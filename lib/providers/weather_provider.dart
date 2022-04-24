import 'dart:convert' as convert;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import "dart:math"; // 체감 온도 계산을 위한 연산 라이브러리
import 'package:intl/intl.dart'; // 날짜 계산을 위한 라이브러리

// Weather 객체 클래스
class WeatherProvider extends ChangeNotifier {
  bool activeFlag = true; // API 요청 무한 루프 방지를 위한 flag
  bool initWeatherFlag = false;

  // 구름 상태 인덱스
  static const _sunny = "1";
  static const _cloudiness = "3";
  static const _cloudy = "4";

  // 강수 형태 인덱스
  static const _rainNo = "0";
  static const _rainRain = "1";
  static const _rainRainAndSnow = "2";
  static const _rainSnow = "3";
  static const _rainDrop = "4";

  final List<HourForecast> _forecastList = [];
  List<HourForecast> get forecastList => _forecastList; // get 필드
  static const int predictMax = 12; // 객체 12개 생성으로 인한 12시간의 날씨 데이터 보유

  // API Key값
  late String _myKey = '';
  bool flagApi = false; // 키값을 1회만 불러오게 하기 위한 flag

  // 해당 API 주소
  final String _requestHost = "apis.data.go.kr";
  final String _requestPath =
      "/1360000/VilageFcstInfoService_2.0/getVilageFcst";

  // 생성자
  WeatherProvider() {
    for (var i = 0; i < predictMax; i++) {
      forecastList.add(HourForecast());
    }
    activeFlag = true;
  }

  // 현재 날씨 정보를 반환

  HourForecast getCurrentWeather() {
    return _forecastList[0];
  }

  // JSON을 통해 키값 불러오기
  Future<bool> initKey() async {
    try {
      _myKey = convert.json.decode(
          await rootBundle.loadString('assets/weather-api.json'))['_mykey'];
      return true;
    } catch (e) {
      return false;
    }
  }

  // 기상 정보(날씨 상태) 설정 함수
  String makeSky(String sky, String rain) {
    String res = "";
    // 오늘 비 예보가 없는 경우, 구름 상태에 따라 기상 정보 제공
    if (rain.compareTo(_rainNo) == 0) {
      switch (sky) {
        case _sunny:
          res = "맑음";
          break;
        case _cloudiness:
          res = "구름많음";
          break;
        case _cloudy:
          res = "흐림";
          break;
      }
    } else {
      switch (rain) {
        case _rainRain:
          res = "비";
          break;
        case _rainRainAndSnow:
          res = "비/눈";
          break;
        case _rainSnow:
          res = "눈";
          break;
        case _rainDrop:
          res = "소나기";
          break;
      }
    }
    return res;
  }

  // 체감 온도 계산 함수
  String makeSTemp(int temp, double windSpeed) {
    var T = temp;
    var V = pow(windSpeed * 3.6, 0.16);

    // 체감온도 계산
    var res = 13.12 + (0.6215 * T) - (11.37 * V) + (0.3965 * V * T);
    return res.round().toString();
  }

  void changeActiveFlag() {
    activeFlag = true;
  }

  // API를 받아서 해당 날씨 데이터를 Weather 객체에 업데이트
  Future<bool> updateWeather(String nx, String ny) async {
    /*
    String basedate   // 기준 날짜    ex) 19700101
    String basetime   // 기준 시간 값     ex) 1200
    String nx   // 기준 위치 X좌표    ex) 59
    String ny   // 기준 위치 Y좌표    ex) 125
    */
    if ((_myKey == '') & (flagApi == false)) {
      // api 키값을 제대로 받아오면 해당 flag를 true로 바꿔 1회만 실행되게 함
      flagApi = await initKey();
    }
    if (activeFlag == false) {
      return false;
    }
    // 현재 시간(now) 기준, 1시간전 시간(anHourBefore) 구하기
    var now = DateTime.now(); //현재일자
    var anHourBefore = now.subtract(const Duration(hours: 1));

    // 날짜 데이터를 받아서 원하는 basetime, basedate 만들기
    String basedate = DateFormat("yyyyMMdd").format(anHourBefore);
    String baseHour = DateFormat("HH").format(anHourBefore);
    String curHour = DateFormat("HH").format(now);

    /*
      Q. 왜 계산을 이렇게 진행 하였는가?
      A. 우리가 날씨 정보를 구하는 단기예보의 데이터의 경우,
      날씨 정보를 업데이트 하는 Base_time이 0200, 0500, 0800, 1100, 1400, 1700, 2000, 2300 총 6개로 구성되어 있다.
      그래서 현재 날씨 정보를 얻으려면 가장 가깝게 업데이트 된 날씨 정보 데이터를 얻어와야 하므로 추가적인 연산을 진행하게 된다
      - 계산 과정 : 0200, 0500, 0800, 1100, 1400, 1700, 2000, 2300 -> 0000, 0300, 0600, 0900, 1200, 1500, 1800, 2100으로 우선 바꾼다
        3으로 나눠 원하는 시간대가 언제인지 구한다 -> 원래 baseTime으로 돌리기 위해 연산을 역으로 진행하기 위해 (*3)+2를 수행한다
      ex) 현재시간 : 1300 -> 13 -> 11-> ~/3 몫 : 3 -> 3*3+2 = 11 -> 1100의 날씨 정보를 받아오면 된다
          따라서 우리가 날씨 정보를 얻기위해 가져올 최신 날씨 정보는 1100 시간의 날씨 정보이다
    */
    int predHour; // 예측 시간값
    // 만약 현재시간이 2시 이전이라면 BaseTime은 전날에 2300이므로 시간과 더불어 날짜도 하루전으로 바꿔야 한다
    if (int.parse(baseHour) < 2) {
      predHour =
          (((int.parse(baseHour) + 22) ~/ 3) * 3) + 2; // 원하는 시간값을 불러올 수 있도록 계산
      anHourBefore = anHourBefore.subtract(const Duration(days: 1));
      basedate = DateFormat("yyyyMMdd").format(anHourBefore);
    } else {
      predHour =
          (((int.parse(baseHour) - 2) ~/ 3) * 3) + 2; // 원하는 시간값을 불러올 수 있도록 계산
    }
    String basetime = predHour.toString().padLeft(2, "0") + "30";
    // 30분으로 시간을 설정한 이유 : API 제공 시간(~이후)이 각 BaseTime +10분이기 때문이다

    try {
      var getTime = predictMax; // 몇 시간의 정보를 가져올 것인가
      // url 변환
      final url = Uri.https(_requestHost, _requestPath, {
        "serviceKey": _myKey,
        "pageNo": "1",
        "numOfRows": ((getTime + 2) * 12)
            .toString(), // 원래 구하는 시간을 기준보다 +2를 하여 BaseTime에 묶여 있는 3시간의 값을 불러와 원하는 시간대의 12시간 데이터를 뽑아내려고 함
        "dataType": "JSON",
        "base_date": basedate,
        "base_time": basetime,
        "nx": nx,
        "ny": ny
      });
      final response = await http.get(url); // http 호출
      // http 호출이 안되면 예외 처리
      if (response.statusCode != 200) {
        throw HttpException('${response.statusCode}');
      }
      // 전체 item 항목을 list로 바꾸고, 해당 카테고리에 맞는 정보만 따로 추출
      final List itemList = (convert.jsonDecode(response.body))['response']
          ['body']['items']['item'];
      // 순서대로 온도, 기상상태, 강수상태, 강수확률, 풍속, 날짜, 시간 데이터를 가져온다
      final Iterable tempList = itemList.where((el) => el['category'] == 'TMP');
      final Iterable skyList = itemList.where((el) => el['category'] == 'SKY');
      final Iterable rainList = itemList.where((el) => el['category'] == 'PTY');
      final Iterable rainRateList =
          itemList.where((el) => el['category'] == 'POP');
      final Iterable windSpeedList =
          itemList.where((el) => el['category'] == 'WSD');

      final Iterable dateList = windSpeedList.map((el) => el['fcstDate']);
      final Iterable timeList = windSpeedList.map((el) => el['fcstTime']);

      print(180);
      int tmp = 0; // 기준 시간으로 부터 차이 나는 시간을 구할때 사용하는 임시 변수
      int idx = 0; // 인덱스 부여용 변수
      // 데이터 업데이트
      for (var i = 0; i < (predictMax + 2); i++) {
        // 12시간 데이터를 전부 받으면 데이터 업데이트 작업을 종료
        if (idx == predictMax) {
          break;
        }
        /* 기준 시간과 얼마나 차이나는지 나머지 연산을 통한 계산 진행
          predHour의 나머지만큼 BaseTime 기준 이후 시간을 구해야 하므로 tmp를 통해 나머지가 0이 될때 까지를 구해 원하는 시간대의 12시간 데이터를 추출한다
          ex) 현재시간 = 1300 -> BaseTime = 1100 -> tmp가 2가 될때 까지 값을 받지 않고, 11시의 2시간 후부터 값을 가져온다
        */
        if ((int.parse(curHour) - tmp) % 3 != 0) {
          tmp++;
          continue;
        } else {
          // 조건에 맞으면 클래스 리스트에 값을 갱신
          forecastList[idx].initHourForecast(
              dateList.elementAt(i), // 날짜
              timeList.elementAt(i), // 시간
              tempList.elementAt(i)['fcstValue'], // 온도
              makeSTemp(
                  int.parse(tempList.elementAt(i)['fcstValue']),
                  double.parse(
                      windSpeedList.elementAt(i)['fcstValue'])), // 체감 온도
              makeSky(skyList.elementAt(i)['fcstValue'],
                  rainList.elementAt(i)['fcstValue']), // 하늘 상태(구름 상태)
              rainRateList.elementAt(i)['fcstValue'], // 강수 확률
              windSpeedList.elementAt(i)['fcstValue']); // 풍속
          idx++; // 다음 인덱스
        }
      }
      initWeatherFlag = true;
      activeFlag = false;
      notifyListeners();
    } on SocketException {
      print('No Internet connection 😑');
    } on HttpException {
      print("Couldn't find the post 😱");
    } on FormatException {
      print("Bad response format 👎");
    } catch (e) {
      print(e);
    }
    return initWeatherFlag;
  }
}

// 시간별 날씨 정보를 담고 있는 객체
class HourForecast {
  // 초기값(Default) 설정
  String _date = "19700101";
  String _time = "10:00"; // 시간
  String _temp = "99"; // 기온
  String _sTemp = "99"; // 체감 온도
  String _sky =
      ""; // 구름 상태 - 맑음, 구름많음, 흐림, 비, 비/눈, 눈, 소나기 <- 초기화 되지 않았을 때는 "" 나오도록 수정했어요
  String _rainRate = "-1"; // 강수 확률
  String _windSpeed = "-1"; // 풍속

  //getter
  String get getDate => _date;
  String get getTime => _time;
  String get getTemp => _temp;
  String get getSTemp => _sTemp;
  String get getSky => _sky;
  String get getRainRate => _rainRate;
  String get getWindSpeed => _windSpeed;

  // Set 함수
  set date(String input) {
    _date = input;
  }

  set time(String input) {
    _time = input;
  }

  set temp(String input) {
    _temp = input;
  }

  set sTemp(String input) {
    _sTemp = input;
  }

  set sky(String input) {
    _sky = input;
  }

  set rainRate(String input) {
    _rainRate = input;
  }

  set windSpeed(String input) {
    _windSpeed = input;
  }

  // 해당 객체 업데이트(갱신)
  void initHourForecast(String newDate, String newTime, String newTemp,
      String newsTemp, String newSky, String newRainRate, String newWindSpeed) {
    date = newDate;
    time = newTime;
    temp = newTemp;
    sky = newSky;
    rainRate = newRainRate;
    sTemp = newsTemp;
    windSpeed = newWindSpeed;
  }
}
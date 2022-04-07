import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sweater/providers/location_info.dart';

class LocationTile extends StatelessWidget {
  final String title;
  bool checked = false;
  bool multi_select = false;
  Function onPressButton = () {};
  final SlidableController slidableController;

  LocationTile({
    Key? key,
    required this.onPressButton,
    required this.slidableController,
    this.title = "menu",
    this.checked = false,
    this.multi_select = false,
  }) : super(key: key);

  void open(BuildContext context) {
    Slidable.of(context)!.open();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Material(
            color: checked ? Colors.blue[200] : Colors.grey[200],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Slidable(
                actionPane: SlidableDrawerActionPane(),
                controller: slidableController,
                actionExtentRatio: 0.15,
                key: const ValueKey(0),
                secondaryActions: <Widget>[
                  SlideAction(
                      color: Colors.white,
                      onTap: () => onPressButton(title),
                      child: Container(
                        height: 100.0,
                        width: 100.0,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            topRight: const Radius.circular(8.0),
                            bottomRight: const Radius.circular(8.0),
                          ),
                        ),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ))
                ],
                child: ListTile(
                  leading: Icon(Icons.location_on_outlined,
                      color: checked ? Colors.blue[400] : Colors.grey[400]),
                  title: Text(title,
                      style: checked
                          ? TextStyle(color: Theme.of(context).primaryColor)
                          : const TextStyle(color: Colors.grey)),
                  trailing: checked
                      ? multi_select
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : const Icon(Icons.check, color: Colors.blue)
                      : const Icon(null),
                ))));
  }
}

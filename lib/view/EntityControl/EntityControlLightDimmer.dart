import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hasskit/helper/GeneralData.dart';
import 'package:hasskit/helper/Logger.dart';
import 'package:hasskit/helper/MaterialDesignIcons.dart';
import 'package:hasskit/helper/WebSocket.dart';
import 'package:hasskit/model/Entity.dart';
import 'package:hasskit/view/EntityControl/RgbColorSelector.dart';
import 'package:provider/provider.dart';

import 'TempColorSelector.dart';

List<Color> colorTemps = [
  Color(0xff64B5F6), //Blue
  Color(0xff90CAF9), //Blue
  Color(0xffBBDEFB), //Blue
  Color(0xffF5F5F5), //Gray
  Color(0xffFFF9C4), //Yellow
  Color(0xffFFF59D), //Yellow
];

class EntityControlLightDimmer extends StatefulWidget {
  final String entityId;
  const EntityControlLightDimmer({@required this.entityId});

  @override
  _EntityControlLightDimmerState createState() =>
      _EntityControlLightDimmerState();
}

class _EntityControlLightDimmerState extends State<EntityControlLightDimmer> {
  @override
  Widget build(BuildContext context) {
//    log.d(
//        "${widget.entityId} entities[widget.entityId].supportedFeaturesLights ${gd.entities[widget.entityId].getSupportedFeaturesLights} ${gd.entities[widget.entityId].supportedFeatures}");
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          LightSlider(
            entityId: widget.entityId,
          ),
          SizedBox(height: 10),
          gd.entities[widget.entityId].getSupportedFeaturesLights
                  .contains("SUPPORT_RGB_COLOR")
              ? RgbColorSelector(
                  entityId: widget.entityId,
                )
              : gd.entities[widget.entityId].getSupportedFeaturesLights
                      .contains("SUPPORT_COLOR_TEMP")
                  ? TempColorSelector(
                      entityId: widget.entityId,
                    )
                  : Container(),
        ],
      ),
    );
  }
}

class LightSlider extends StatefulWidget {
  final String entityId;

  const LightSlider({@required this.entityId});

  @override
  State<StatefulWidget> createState() {
    return new LightSliderState();
  }
}

class LightSliderState extends State<LightSlider> {
  double buttonHeight = 300.0;
  double buttonWidth = 93.75;
  double currentPosX;
  double currentPosY;
  double startPosX;
  double startPosY;
  Offset buttonPos;
  double buttonValue = 0;
  double upperPartHeight = 30.0;
  double lowerPartHeight = 50.0;
  double buttonValueOnTapDown = 0;
  String raisedButtonLabel = "";
  //creating Key for red panel
  GlobalKey buttonKey = GlobalKey();
  DateTime draggingTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Selector<GeneralData, String>(
      selector: (_, generalData) =>
          "${generalData.entities[widget.entityId].state} " +
          "${generalData.entities[widget.entityId].brightness} " +
          "${generalData.entities[widget.entityId].colorTemp} " +
          "${generalData.entities[widget.entityId].rgbColor} ",
      builder: (context, data, child) {
        if (draggingTime.millisecondsSinceEpoch <
            DateTime.now().millisecondsSinceEpoch) {
          if (!gd.entities[widget.entityId].isStateOn) {
            buttonValue = lowerPartHeight;
          } else {
            var mapValue = gd.mapNumber(
                gd.entities[widget.entityId].brightness.toDouble(),
                0,
                255,
                lowerPartHeight,
                buttonHeight - upperPartHeight);
            buttonValue = mapValue;
          }
        }
        Color sliderColor;
        if (!gd.entities[widget.entityId].isStateOn) {
          sliderColor = Color.fromRGBO(128, 128, 128, 1.0);
        } else if (gd.entities[widget.entityId].getSupportedFeaturesLights
            .contains("SUPPORT_RGB_COLOR")) {
          var entityRGB = gd.entities[widget.entityId].rgbColor;
          if (entityRGB == null ||
              entityRGB.length < 3 ||
              entityRGB[0] > 250 && entityRGB[1] > 250 && entityRGB[2] > 250)
            entityRGB = [224, 224, 224];
          sliderColor =
              Color.fromRGBO(entityRGB[0], entityRGB[1], entityRGB[2], 1.0);
        } else if (gd.entities[widget.entityId].getSupportedFeaturesLights
                .contains("SUPPORT_COLOR_TEMP") &&
            gd.entities[widget.entityId].colorTemp != null &&
            gd.entities[widget.entityId].maxMireds != null &&
            gd.entities[widget.entityId].minMireds != null) {
          var colorTemp = gd.entities[widget.entityId].colorTemp;
          var minMireds = gd.entities[widget.entityId].minMireds;
          var maxMireds = gd.entities[widget.entityId].maxMireds;
          var miredsDivided = (maxMireds - minMireds) / colorTemps.length;
          var miredsDividedHalf = miredsDivided / 2;
//          log.d(
//              "colorTemp $colorTemp minMireds $minMireds maxMireds $maxMireds miredsDivided $miredsDivided");
          if (colorTemp <= minMireds + miredsDivided * 1 - miredsDividedHalf)
            sliderColor = colorTemps[0];
          else if (colorTemp <=
              minMireds + miredsDivided * 2 - miredsDividedHalf)
            sliderColor = colorTemps[1];
          else if (colorTemp <=
              minMireds + miredsDivided * 3 - miredsDividedHalf)
            sliderColor = colorTemps[2];
          else if (colorTemp <=
              minMireds + miredsDivided * 4 - miredsDividedHalf)
            sliderColor = colorTemps[3];
          else if (colorTemp <=
              minMireds + miredsDivided * 5 - miredsDividedHalf)
            sliderColor = colorTemps[4];
          else
            sliderColor = colorTemps[5];
        } else {
          sliderColor = colorTemps[0];
        }

        return new GestureDetector(
          onVerticalDragStart: (DragStartDetails details) =>
              _onVerticalDragStart(context, details),
          onVerticalDragUpdate: (DragUpdateDetails details) =>
              _onVerticalDragUpdate(context, details),
          onVerticalDragEnd: (DragEndDetails details) => _onVerticalDragEnd(
              context, details, gd.entities[widget.entityId]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  Container(
                    key: buttonKey,
                    width: buttonWidth,
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius:
                              0.0, // has the effect of softening the shadow
                          spreadRadius:
                              1.0, // has the effect of extending the shadow
                          offset: Offset(
                            0.0, // horizontal, move right 10
                            0.0, // vertical, move down 10
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: Container(
                      width: buttonWidth,
                      height: buttonHeight > 0 ? buttonHeight : 0,
                      decoration: BoxDecoration(
                        color: sliderColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: buttonWidth,
                        height: buttonValue > 0 ? buttonValue : 0,
                        alignment: Alignment.topCenter,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16)),
                        ),
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(
                            MaterialDesignIcons.getIconDataFromIconName(
                                gd.entities[widget.entityId].getDefaultIcon),
                            size: 45,
                            color: sliderColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: Container(
                      width: buttonWidth,
                      height: upperPartHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        gd
                            .mapNumber(buttonValue, lowerPartHeight,
                                buttonHeight - upperPartHeight, 0, 100)
                            .toInt()
                            .toString(),
                        style: TextStyle(
                          fontSize: 20,
                          color: sliderColor,
                        ),
                      ),
                    ),
                  )
                ],
              ),
//              Text("${gd.entities[widget.entityId].rgbColor}"),
            ],
          ),
        );
      },
    );
  }

  _onVerticalDragStart(BuildContext context, DragStartDetails details) {
    final RenderBox box = context.findRenderObject();
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    setState(() {
      draggingTime = DateTime.now().add(Duration(seconds: 1));
      startPosX = localOffset.dx;
      startPosY = localOffset.dy;
      buttonValueOnTapDown = buttonValue;
      log.d(
          "_onVerticalDragStart startPosX ${startPosX.toStringAsFixed(0)} startPosY ${startPosY.toStringAsFixed(0)}");
    });
  }

  _onVerticalDragEnd(
      BuildContext context, DragEndDetails details, Entity entity) {
    setState(
      () {
        draggingTime = DateTime.now().add(Duration(seconds: 1));
        var sendValue = gd.mapNumber(buttonValue, lowerPartHeight,
            buttonHeight - upperPartHeight, 0, 255);
        log.d("_onVerticalDragEnd $sendValue");
        var outMsg;
        if (sendValue <= 0) {
          outMsg = {
            "id": gd.socketId,
            "type": "call_service",
            "domain": entity.entityId.split('.').first,
            "service": "turn_off",
            "service_data": {
              "entity_id": entity.entityId,
            },
          };
        } else {
          outMsg = {
            "id": gd.socketId,
            "type": "call_service",
            "domain": entity.entityId.split('.').first,
            "service": "turn_on",
            "service_data": {
              "entity_id": entity.entityId,
              "brightness": sendValue.toInt()
            },
          };
        }
        var outMsgEncoded = json.encode(outMsg);
        webSocket.send(outMsgEncoded);
        HapticFeedback.mediumImpact();
      },
    );
  }

  _onVerticalDragUpdate(BuildContext context, DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject();
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    setState(() {
      draggingTime = DateTime.now().add(Duration(seconds: 1));
      currentPosX = localOffset.dx;
      currentPosY = localOffset.dy;
//      log.d(
//          "_onVerticalDragUpdate currentPosX ${currentPosX.toStringAsFixed(0)} currentPosY ${currentPosY.toStringAsFixed(0)}");
      buttonValue = buttonValueOnTapDown + (startPosY - currentPosY);
      buttonValue =
          buttonValue.clamp(lowerPartHeight, buttonHeight - upperPartHeight);
    });
  }
}

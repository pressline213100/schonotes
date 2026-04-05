import 'dart:typed_data';
import 'layer.dart';
import 'stroke.dart';

class Note {
  String id;
  String title;
  DateTime lastModified;
  String? coverUrl;
  int coverColorValue; 
  String backgroundTemplate; 
  String paperColor; 
  List<PageData> pages;
  
  Note({
    required this.id,
    required this.title,
    required this.lastModified,
    this.coverUrl,
    this.coverColorValue = 0xFF2196F3, 
    this.backgroundTemplate = 'grid',
    this.paperColor = 'white',
    List<PageData>? pages,
  }) : pages = pages ?? [
    PageData(id: 'page_1'), 
    PageData(id: 'page_2'),
    PageData(id: 'page_3') 
  ];

  Note copy() {
    return Note(
      id: id,
      title: title,
      lastModified: lastModified,
      coverUrl: coverUrl,
      coverColorValue: coverColorValue,
      backgroundTemplate: backgroundTemplate,
      paperColor: paperColor,
      pages: pages.map((p) => p.copy()).toList(),
    );
  }
}

class PageData {
  String id;
  List<LayerData> layers;
  Uint8List? pdfBytes; 
  List<CanvasItem> items; 
  
  PageData({
    required this.id,
    List<LayerData>? layers,
    this.pdfBytes,
    List<CanvasItem>? items,
  }) : 
    layers = layers ?? [
      LayerData(id: 'layer_1', name: 'Layer 1'),
      LayerData(id: 'layer_2', name: 'Background Layer')
    ],
    items = items ?? [];

  PageData copy() {
    return PageData(
      id: id,
      pdfBytes: pdfBytes,
      layers: layers.map((l) => l.copy()).toList(),
      items: items.map((i) => i.copy()).toList(),
    );
  }
}

abstract class CanvasItem {
  String id;
  double x;
  double y;
  double width;
  double height;
  bool isLocked = false;
  
  CanvasItem(this.id, this.x, this.y, this.width, this.height, {this.isLocked = false});
  CanvasItem copy();
}

class ImageItem extends CanvasItem {
  Uint8List imageBytes;
  ImageItem(String id, double x, double y, double width, double height, this.imageBytes, {super.isLocked}) 
    : super(id, x, y, width, height);

  @override
  ImageItem copy() => ImageItem(
    id, x, y, width, height, imageBytes, isLocked: isLocked
  );
}

class TextItem extends CanvasItem {
  String text;
  double fontSize;
  TextItem(String id, double x, double y, double width, double height, this.text, {this.fontSize = 16, super.isLocked}) 
    : super(id, x, y, width, height);

  @override
  TextItem copy() => TextItem(
    id, x, y, width, height, text, fontSize: fontSize, isLocked: isLocked
  );
}

class AudioItem extends CanvasItem {
  int durationSeconds;
  AudioItem(String id, double x, double y, double width, double height, this.durationSeconds, {super.isLocked}) 
    : super(id, x, y, width, height);

  @override
  AudioItem copy() => AudioItem(
    id, x, y, width, height, durationSeconds, isLocked: isLocked
  );
}

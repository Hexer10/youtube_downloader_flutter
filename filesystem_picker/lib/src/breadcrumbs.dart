import 'package:flutter/material.dart';
import 'listview_extensions.dart';

class BreadcrumbItem<T> {
  final String text;
  final T data;
  final ValueChanged<T> onSelect;

  BreadcrumbItem({
    @required this.text,
    this.data,
    this.onSelect,
  });
}

class Breadcrumbs<T> extends StatelessWidget {
  final List<BreadcrumbItem<T>> items;
  final double height;
  final Color textColor;
  final ValueChanged<T> onSelect;

  final ScrollController _scrollController = ScrollController();

  Breadcrumbs({
    Key key,
    @required this.items,
    this.height = 50,
    this.textColor,
    this.onSelect,
  }) : super(key: key);

  _scrollToEnd() async {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());

    final Color defaultTextColor = Theme.of(context).textTheme.button.color;

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment(0.7, 0.5),
          end: Alignment.centerRight,
          colors: <Color>[Colors.white, Colors.transparent],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Container(
        alignment: Alignment.topLeft,
        height: height,
        child: ListViewExtended.separatedWithHeaderFooter(
          controller: _scrollController,
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return ButtonTheme(
              minWidth: 48,
              padding: EdgeInsets.symmetric(
                      vertical: ButtonTheme.of(context).padding.vertical) +
                  const EdgeInsets.symmetric(horizontal: 8),
              child: FlatButton(
                textColor: (index == (items.length - 1))
                    ? (textColor ?? defaultTextColor)
                    : (textColor ?? defaultTextColor).withOpacity(0.75),
                child: Text(items[index].text),
                onPressed: () {
                  if (items[index].onSelect != null) {
                    items[index].onSelect(items[index].data);
                  }
                  if (onSelect != null) {
                    onSelect(items[index].data);
                  }
                },
              ),
            );
          },
          separatorBuilder: (_, __) => Container(
            alignment: Alignment.center,
            child: Icon(
              Icons.chevron_right,
              color: (textColor ?? defaultTextColor).withOpacity(0.45),
            ),
          ),
          headerBuilder: (_) =>
              SizedBox(width: ButtonTheme.of(context).padding.horizontal - 8),
          footerBuilder: (_) => const SizedBox(width: 70),
        ),
      ),
    );
  }
}

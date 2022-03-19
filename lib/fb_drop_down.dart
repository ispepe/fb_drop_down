library fb_dropdown;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'src/motion/page_transitions.dart';
import 'src/hover_button.dart';
// import 'text_box.dart';

enum TextChangedReason {
  /// Whether the text in an [FBDropDown] was changed by user input
  userInput,

  /// Whether the text in an [FBDropDown] was changed because the user
  /// chose the suggestion
  suggestionChosen,
}

// TODO: Navigate through items using keyboard (https://github.com/bdlukaa/fluent_ui/issues/19)

/// An AutoSuggestBox provides a list of suggestions for a user to select from
/// as they type.
///
/// ![AutoSuggestBox Preview](https://docs.microsoft.com/en-us/windows/apps/design/controls/images/controls-autosuggest-expanded-01.png)
///
/// See also:
///
///   * <https://docs.microsoft.com/en-us/windows/apps/design/controls/auto-suggest-box>
///   * [TextBox], which is used by this widget to enter user text input
///   * [Overlay], which is used to show the suggestion popup
class FBDropDown extends StatefulWidget {
  /// Creates a fluent-styled auto suggest box.
  const FBDropDown({
    Key? key,
    required this.items,
    this.value = '',
    this.onSelected,
    this.leadingIcon,
    this.trailingIcon,
    this.clearButtonEnabled = true,
    this.placeholder,
    this.placeholderStyle,
    this.style,
    this.decoration,
    this.foregroundDecoration,
    this.highlightColor,
  }) : super(key: key);

  /// The list of items to display to the user to pick
  final List<String> items;

  /// The controller used to have control over what to show on
  /// the [TextBox].
  // final TextEditingController? controller;
  /// 默认选中项
  final String value;

  /// Called when the text is updated
  // final void Function(String text, TextChangedReason reason)? onChanged;

  /// Called when the user selected a value.
  final ValueChanged<String>? onSelected;

  /// A widget displayed at the start of the text box
  ///
  /// Usually an [IconButton] or [Icon]
  final Widget? leadingIcon;

  /// A widget displayed at the end of the text box
  ///
  /// Usually an [IconButton] or [Icon]
  final Widget? trailingIcon;

  /// Whether the close button is enabled
  ///
  /// Defauls to true
  final bool clearButtonEnabled;

  /// The text shown when the text box is empty
  ///
  /// See also:
  ///
  ///  * [TextBox.placeholder]
  final String? placeholder;

  /// The style of [placeholder]
  ///
  /// See also:
  ///
  ///  * [TextBox.placeholderStyle]
  final TextStyle? placeholderStyle;

  /// The style to use for the text being edited.
  final TextStyle? style;

  /// Controls the [BoxDecoration] of the box behind the text input.
  final BoxDecoration? decoration;

  /// Controls the [BoxDecoration] of the box in front of the text input.
  ///
  /// If [highlightColor] is provided, this must not be provided
  final BoxDecoration? foregroundDecoration;

  /// The highlight color of the text box.
  ///
  /// If [foregroundDecoration] is provided, this must not be provided.
  final Color? highlightColor;

  @override
  _FBDropDownState createState() => _FBDropDownState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<String>('items', items));
    properties.add(ObjectFlagProperty<ValueChanged<String>?>(
      'onSelected',
      onSelected,
      ifNull: 'disabled',
    ));
    properties.add(FlagProperty(
      'clearButtonEnabled',
      value: clearButtonEnabled,
      defaultValue: true,
      ifFalse: 'clear button disabled',
    ));
  }

  static List defaultItemSorter<T>(String text, List items) {
    return items.where((element) {
      return element.toString().toLowerCase().contains(text.toLowerCase());
    }).toList();
  }
}

class _FBDropDownState<T> extends State<FBDropDown> {
  final FocusNode focusNode = FocusNode();
  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _textBoxKey = GlobalKey();

  final FocusScopeNode overlayNode = FocusScopeNode();

  ValueNotifier<String> get selectedItem => _selectedItem;
  final ValueNotifier<String> _selectedItem = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _selectedItem.value = widget.value;
    focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    focusNode.removeListener(_handleFocusChanged);

    super.dispose();
  }

  void _handleFocusChanged() {
    final hasFocus = focusNode.hasFocus;
    if (!hasFocus) {
      _dismissOverlay();
    } else {
      _showOverlay();
    }
    setState(() {});
  }

  void _insertOverlay() {
    _entry = OverlayEntry(builder: (context) {
      final context = _textBoxKey.currentContext;
      if (context == null) return const SizedBox.shrink();
      final box = _textBoxKey.currentContext!.findRenderObject() as RenderBox;
      final child = Positioned(
        width: box.size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, box.size.height + 0.8),
          child: SizedBox(
            width: box.size.width,
            child: _AutoSuggestBoxOverlay(
              node: overlayNode,
              // controller: controller,
              items: widget.items,
              onSelected: (String item) {
                widget.onSelected?.call(item);
                _selectedItem.value = item;
                // controller.text = item;
                // controller.selection = TextSelection.collapsed(
                //   offset: item.length,
                // );
                // widget.onChanged?.call(item, TextChangedReason.userInput);

                // After selected, the overlay is dismissed and the text box is
                // unfocused
                _dismissOverlay();
                focusNode.unfocus();
              },
              selectedItem: _selectedItem.value,
            ),
          ),
        ),
      );

      return child;
    });

    if (_textBoxKey.currentContext != null) {
      Overlay.of(context)?.insert(_entry!);
      if (mounted) setState(() {});
    }
  }

  void _dismissOverlay() {
    _entry?.remove();
    _entry = null;
  }

  void _showOverlay() {
    if (_entry == null && !(_entry?.mounted ?? false)) {
      _insertOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Actions(
        actions: {
          DirectionalFocusIntent: _DirectionalFocusAction(),
        },
        child: ValueListenableBuilder<String>(
          valueListenable: selectedItem,
          builder: (context, item, child) {
            return TextButton(
              key: _textBoxKey,
              style: ButtonStyle(
                overlayColor:
                    MaterialStateProperty.all<Color>(Colors.transparent),
                alignment: Alignment.centerLeft,
                minimumSize:
                    MaterialStateProperty.all<Size>(const Size(120, 40)),
                padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    const EdgeInsets.symmetric(horizontal: 12)),
                shape: MaterialStateProperty.all<OutlinedBorder>(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  ),
                ),
                backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                side: MaterialStateProperty.resolveWith<BorderSide>((states) {
                  if (_entry != null ||
                      states.contains(MaterialState.hovered) ||
                      states.contains(MaterialState.pressed)) {
                    return const BorderSide(
                      color: Color(0xFF198CFE),
                      width: 1,
                    );
                  }
                  return const BorderSide(
                    color: Color(0x298D93A6),
                    width: 1,
                  );
                }),
              ),
              focusNode: focusNode,
              onPressed: () {
                // widget.onChanged?.call('', TextChangedReason.userInput);
                if (_entry != null) {
                  _dismissOverlay();
                } else {
                  _showOverlay();
                }
              },
              child: Row(
                children: [
                  if (item.isEmpty)
                    Text(
                      '请选择圈子频道',
                      style: TextStyle(
                          color: const Color(0xFF5C6273).withOpacity(0.48),
                          fontSize: 14),
                    )
                  else
                    Text(
                      item,
                      style: const TextStyle(
                          color: Color(0xFF1F2126), fontSize: 14),
                    ),
                  const Expanded(child: SizedBox()),
                  if (_entry != null)
                    const Icon(
                      Icons.arrow_drop_up,
                      color: Color(0xFF1F2126),
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.arrow_drop_down,
                      color: const Color(0xFF5C6273).withOpacity(0.48),
                      size: 20,
                    )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DirectionalFocusAction extends DirectionalFocusAction {
  @override
  void invoke(covariant DirectionalFocusIntent intent) {
    // if (!intent.ignoreTextFields || !_isForTextField) {
    //   primaryFocus!.focusInDirection(intent.direction);
    // }
    debugPrint(intent.direction.toString());
  }
}

class _AutoSuggestBoxOverlay extends StatelessWidget {
  const _AutoSuggestBoxOverlay({
    Key? key,
    required this.items,
    // required this.controller,
    required this.selectedItem,
    required this.onSelected,
    required this.node,
  }) : super(key: key);

  final List<String> items;
  final String selectedItem;

  // final TextEditingController controller;
  final ValueChanged<String> onSelected;
  final FocusScopeNode node;

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: node,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 368),
        decoration: const ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
          ),
          color: Colors.white,
          shadows: [
            BoxShadow(
              color: Color(0x338D93A6),
              offset: Offset(0, 8),
              blurRadius: 16.0,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
            border: Border.all(
              color: const Color(0x298D93A6),
            ),
          ),
          child: Builder(
            builder: (context) {
              /// 可以让外部控制排序
              // final items = FBDropDown.defaultItemSorter(
              //   // value.text
              //   selectedItem,
              //   this.items,
              // );

              late Widget result;
              if (items.isEmpty) {
                result = const Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: _AutoSuggestBoxOverlayTile(text: '什么也没有~'),
                );
              } else {
                result = ListView(
                  key: ValueKey<int>(items.length),
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 4.0),
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    return _AutoSuggestBoxOverlayTile(
                      text: item,
                      isSelected: item == selectedItem,
                      onSelected: () => onSelected.call(item),
                    );
                  }),
                );
              }
              return result;
            },
          ),
        ),
      ),
    );
  }
}

class _AutoSuggestBoxOverlayTile extends StatefulWidget {
  const _AutoSuggestBoxOverlayTile({
    Key? key,
    required this.text,
    this.onSelected,
    this.isSelected = false,
  }) : super(key: key);

  final String text;
  final VoidCallback? onSelected;

  final bool isSelected;

  @override
  __AutoSuggestBoxOverlayTileState createState() =>
      __AutoSuggestBoxOverlayTileState();
}

class __AutoSuggestBoxOverlayTileState extends State<_AutoSuggestBoxOverlayTile>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  final node = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 125),
    );
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HoverButton(
      focusNode: node,
      onPressed: widget.onSelected,
      margin: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
      builder: (context, states) => Stack(
        children: [
          Container(
            height: 32.0,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: widget.isSelected
                  ? const Color(0xFF8D93A6).withOpacity(0.12)
                  : uncheckedInputColor(theme, states),
            ),
            alignment: AlignmentDirectional.centerStart,
            child: EntrancePageTransition(
              child: Text(
                widget.text,
                style: theme.textTheme.bodyText2
                    ?.copyWith(fontSize: 14, color: const Color(0xFF1F2126)),
              ),
              animation: Tween<double>(
                begin: 0.75,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: controller,
                curve: Curves.easeOut,
              )),
              vertical: true,
            ),
          ),

          /// 弄了一个选中的标记
          if (states.isFocused)
            Positioned(
              top: 11.0,
              bottom: 11.0,
              left: 0.0,
              child: Container(
                width: 3.0,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color uncheckedInputColor(ThemeData style, Set<ButtonStates> states) {
    if (states.isDisabled) return style.disabledColor;
    if (states.isPressing) return const Color(0xFF8D93A6).withOpacity(0.080);
    if (states.isHovering) return const Color(0xFF8D93A6).withOpacity(0.12);
    return Colors.transparent;
  }
}

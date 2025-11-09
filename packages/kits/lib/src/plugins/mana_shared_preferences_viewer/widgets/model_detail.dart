import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mana_kits/src/i18n/i18n_mixin.dart';

import 'model.dart' show Model;

class ModelDetail extends StatefulWidget {
  final Model model;
  final VoidCallback? onClose;
  final void Function(Model model)? onSave;

  const ModelDetail({
    super.key,
    required this.model,
    this.onClose,
    this.onSave,
  });

  @override
  State<ModelDetail> createState() => _ModelDetailState();
}

class _ModelDetailState extends State<ModelDetail> with I18nMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _keyController;
  late final TextEditingController _valueController;
  late String _selectedKind;

  final List<String> _kindOptions = [
    'string',
    'int',
    'double',
    'bool',
    'List<String>',
  ];

  @override
  void initState() {
    super.initState();

    _keyController = TextEditingController(text: widget.model.key);
    _valueController = TextEditingController(text: widget.model.value);

    _selectedKind =
        _kindOptions.contains(widget.model.kind)
            ? widget.model.kind
            : _kindOptions.first;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  bool isDouble(String s) {
    return double.tryParse(s) != null;
  }

  bool isBool(String s) {
    final lowerCaseS = s.toLowerCase();
    return lowerCaseS == 'true' || lowerCaseS == 'false';
  }

  bool isInt(String s) {
    return int.tryParse(s) != null;
  }

  bool isListOfString(String s) {
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        return decoded.every((element) => element is String);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedKind,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: t('shared_preferences_viewer.type'),
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(fontSize: 14, color: Colors.black),
              items:
                  _kindOptions.map((String kind) {
                    var style = const TextStyle(fontSize: 14);

                    if (kind == widget.model.kind) {
                      style = const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      );
                    }

                    return DropdownMenuItem<String>(
                      value: kind,
                      child: Text(kind, style: style),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedKind = newValue!;
                });
              },
            ),
            TextFormField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: t('shared_preferences_viewer.key'),
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return t('shared_preferences_viewer.key_required');
                }
                return null;
              },
            ),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: t('shared_preferences_viewer.value'),
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              minLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return t('shared_preferences_viewer.value_required');
                }
                switch (_selectedKind) {
                  case 'double':
                    if (isDouble(value)) {
                      return null;
                    }
                    return t('shared_preferences_viewer.value_must_double');
                  case 'bool':
                    if (isBool(value)) {
                      return null;
                    }
                    return t('shared_preferences_viewer.value_must_bool');
                  case 'int':
                    if (isInt(value)) {
                      return null;
                    }
                    return t('shared_preferences_viewer.value_must_int');
                  case 'List<String>':
                    if (isListOfString(value)) {
                      return null;
                    }
                    return t(
                      'shared_preferences_viewer.value_must_list_of_string',
                    );
                  default:
                    return null;
                }
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      t('shared_preferences_viewer.save'),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      t('shared_preferences_viewer.cancel'),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedModel = Model(
        widget.model.index,
        _keyController.text,
        _valueController.text,
        _selectedKind,
      );

      if (updatedModel.key == widget.model.key &&
          updatedModel.value == widget.model.value &&
          updatedModel.kind == widget.model.kind) {
        widget.onClose?.call();
        return;
      }

      widget.onSave?.call(updatedModel);
    }
  }
}

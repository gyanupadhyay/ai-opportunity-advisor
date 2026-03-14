import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../models/opportunity.dart';

class OpportunityForm extends StatefulComponent {
  final Opportunity? existing;
  final void Function(Map<String, dynamic> data) onSave;
  final void Function() onCancel;

  const OpportunityForm({
    this.existing,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  @override
  State<OpportunityForm> createState() => _OpportunityFormState();
}

class _OpportunityFormState extends State<OpportunityForm> {
  final _titleKey = GlobalNodeKey<web.HTMLInputElement>();
  final _countryKey = GlobalNodeKey<web.HTMLInputElement>();
  final _fieldKey = GlobalNodeKey<web.HTMLInputElement>();
  final _deadlineKey = GlobalNodeKey<web.HTMLInputElement>();
  final _descKey = GlobalNodeKey<web.HTMLTextAreaElement>();
  final _linkKey = GlobalNodeKey<web.HTMLInputElement>();

  String _type = 'scholarship';
  String _educationLevel = 'any';

  @override
  void initState() {
    super.initState();
    final e = component.existing;
    if (e != null) {
      _type = e.type.isNotEmpty ? e.type : 'scholarship';
      _educationLevel = e.educationLevel.isNotEmpty ? e.educationLevel : 'any';
    }
  }

  void _handleSubmit() {
    final data = <String, dynamic>{
      'title': _titleKey.currentNode?.value ?? '',
      'type': _type,
      'country': _countryKey.currentNode?.value ?? '',
      'field': _fieldKey.currentNode?.value ?? '',
      'educationLevel': _educationLevel,
      'deadline': _deadlineKey.currentNode?.value ?? '',
      'description': _descKey.currentNode?.value ?? '',
      'applicationLink': _linkKey.currentNode?.value ?? '',
    };

    if ((data['title'] as String).isEmpty) return;
    component.onSave(data);
  }

  Component _textField(String labelText, GlobalNodeKey inputKey, String initial) {
    return div(classes: 'form-group', [
      label([.text(labelText)]),
      input<String>(
        key: inputKey,
        classes: 'form-input',
        type: InputType.text,
        value: initial,
      ),
    ]);
  }

  @override
  Component build(BuildContext context) {
    final e = component.existing;

    return div(classes: 'admin-form-overlay', [
      div(classes: 'admin-form', [
        h3([.text(e != null ? 'Edit Opportunity' : 'Add Opportunity')]),
        _textField('Title *', _titleKey, e?.title ?? ''),
        div(classes: 'form-group', [
          label([.text('Type')]),
          select([
            for (final t in [
              'scholarship', 'internship', 'fellowship',
              'research', 'exchange', 'summit',
            ])
              option(
                value: t,
                selected: t == _type,
                [.text(t[0].toUpperCase() + t.substring(1))],
              ),
          ],
            classes: 'form-input',
            events: {
              'change': (event) {
                final sel = event.target as web.HTMLSelectElement;
                _type = sel.value;
              },
            },
          ),
        ]),
        _textField('Country', _countryKey, e?.country ?? ''),
        _textField('Field', _fieldKey, e?.field ?? ''),
        div(classes: 'form-group', [
          label([.text('Education Level')]),
          select([
            for (final lvl in ['any', 'undergraduate', 'graduate', 'phd'])
              option(
                value: lvl,
                selected: lvl == _educationLevel,
                [.text(lvl[0].toUpperCase() + lvl.substring(1))],
              ),
          ],
            classes: 'form-input',
            events: {
              'change': (event) {
                final sel = event.target as web.HTMLSelectElement;
                _educationLevel = sel.value;
              },
            },
          ),
        ]),
        _textField('Deadline', _deadlineKey, e?.deadline ?? ''),
        div(classes: 'form-group', [
          label([.text('Description')]),
          textarea(
            key: _descKey,
            classes: 'form-input form-textarea',
            attributes: {'rows': '3'},
            [.text(e?.description ?? '')],
          ),
        ]),
        _textField('Application Link', _linkKey, e?.applicationLink ?? ''),
        div(classes: 'form-actions', [
          button(
            classes: 'admin-btn admin-btn-save',
            onClick: _handleSubmit,
            [.text('Save')],
          ),
          button(
            classes: 'admin-btn admin-btn-cancel',
            onClick: component.onCancel,
            [.text('Cancel')],
          ),
        ]),
      ]),
    ]);
  }
}

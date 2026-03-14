import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:web/web.dart' as web;

import '../models/opportunity.dart';
import '../services/api_service.dart';
import '../components/opportunity_form.dart';

class AdminPage extends StatefulComponent {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String? _password;
  bool _loginError = false;
  bool _loading = false;
  List<Opportunity> _opportunities = [];
  String _searchQuery = '';
  Opportunity? _editing;
  bool _showForm = false;
  String? _errorMessage;

  final _passwordKey = GlobalNodeKey<web.HTMLInputElement>();

  Future<void> _login() async {
    final pw = _passwordKey.currentNode?.value ?? '';
    if (pw.isEmpty) return;

    setState(() {
      _loading = true;
      _loginError = false;
    });

    try {
      final opps = await ApiService.adminListOpportunities(pw);
      setState(() {
        _password = pw;
        _opportunities = opps;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loginError = true;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_password == null) return;
    setState(() => _loading = true);

    try {
      final opps = await ApiService.adminListOpportunities(_password!);
      setState(() {
        _opportunities = opps;
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to refresh: $e';
        _loading = false;
      });
    }
  }

  Future<void> _save(Map<String, dynamic> data) async {
    if (_password == null) return;
    setState(() => _loading = true);

    try {
      if (_editing != null && _editing!.id.isNotEmpty) {
        await ApiService.adminUpdateOpportunity(
            _password!, _editing!.id, data);
      } else {
        await ApiService.adminCreateOpportunity(_password!, data);
      }
      setState(() {
        _showForm = false;
        _editing = null;
      });
      await _refresh();
    } catch (e) {
      setState(() {
        _errorMessage = 'Save failed: $e';
        _loading = false;
      });
    }
  }

  Future<void> _delete(Opportunity opp) async {
    if (_password == null || opp.id.isEmpty) return;
    setState(() => _loading = true);

    try {
      await ApiService.adminDeleteOpportunity(_password!, opp.id);
      await _refresh();
    } catch (e) {
      setState(() {
        _errorMessage = 'Delete failed: $e';
        _loading = false;
      });
    }
  }

  List<Opportunity> get _filtered {
    if (_searchQuery.isEmpty) return _opportunities;
    final q = _searchQuery.toLowerCase();
    return _opportunities
        .where((o) =>
            o.title.toLowerCase().contains(q) ||
            o.type.toLowerCase().contains(q) ||
            o.country.toLowerCase().contains(q) ||
            o.field.toLowerCase().contains(q))
        .toList();
  }

  Component _buildLogin() {
    return div(classes: 'admin-login', [
      div(classes: 'admin-login-card', [
        h2([.text('\u{1F512} Admin Panel')]),
        p([.text('Enter the admin password to manage opportunities.')]),
        input<String>(
          key: _passwordKey,
          classes: 'form-input',
          type: InputType.password,
          attributes: {'placeholder': 'Admin password'},
          events: {
            'keydown': (event) {
              final ke = event as web.KeyboardEvent;
              if (ke.key == 'Enter') _login();
            },
          },
        ),
        if (_loginError)
          p(classes: 'admin-error', [.text('Invalid password. Try again.')]),
        button(
          classes: 'admin-btn admin-btn-save',
          disabled: _loading,
          onClick: _login,
          [.text(_loading ? 'Checking...' : 'Login')],
        ),
      ]),
    ]);
  }

  Component _buildDashboard() {
    final filtered = _filtered;

    return div(classes: 'admin-dashboard', [
      div(classes: 'admin-header', [
        div(classes: 'admin-header-left', [
          Link(
            to: '/',
            child: span(classes: 'back-btn', [.text('\u{2190} Home')]),
          ),
          h2([.text('Manage Opportunities')]),
          span(classes: 'admin-count', [
            .text('${_opportunities.length} total'),
          ]),
        ]),
        div(classes: 'admin-header-right', [
          button(
            classes: 'admin-btn admin-btn-save',
            onClick: () {
              setState(() {
                _editing = null;
                _showForm = true;
              });
            },
            [.text('+ Add New')],
          ),
        ]),
      ]),
      if (_errorMessage != null)
        div(classes: 'admin-error-bar', [
          .text(_errorMessage!),
          button(
            classes: 'admin-btn-dismiss',
            onClick: () => setState(() => _errorMessage = null),
            [.text('\u{2715}')],
          ),
        ]),
      div(classes: 'admin-search', [
        input<String>(
          classes: 'form-input',
          type: InputType.text,
          attributes: {
            'placeholder': 'Search by title, type, country, field...'
          },
          onInput: (value) {
            _searchQuery = value;
            setState(() {});
          },
        ),
      ]),
      if (_loading)
        div(classes: 'admin-loading', [.text('Loading...')])
      else
        div(classes: 'admin-table-wrap', [
          table(classes: 'admin-table', [
            thead([
              tr([
                for (final h in [
                  'Title', 'Type', 'Country', 'Field',
                  'Level', 'Deadline', 'Source', 'Actions',
                ])
                  th([.text(h)]),
              ]),
            ]),
            tbody([
              for (final opp in filtered)
                tr([
                  td(classes: 'td-title', [.text(opp.title)]),
                  td([
                    span(classes: 'badge badge-${opp.type}', [.text(opp.type)]),
                  ]),
                  td([.text(opp.country)]),
                  td([.text(opp.field)]),
                  td([.text(opp.educationLevel)]),
                  td([.text(opp.deadline)]),
                  td([
                    span(
                      classes: 'badge badge-source-${opp.source}',
                      [.text(opp.source)],
                    ),
                  ]),
                  td(classes: 'td-actions', [
                    button(
                      classes: 'admin-btn-sm admin-btn-edit',
                      onClick: () {
                        setState(() {
                          _editing = opp;
                          _showForm = true;
                        });
                      },
                      [.text('Edit')],
                    ),
                    button(
                      classes: 'admin-btn-sm admin-btn-delete',
                      onClick: () => _delete(opp),
                      [.text('Delete')],
                    ),
                  ]),
                ]),
            ]),
          ]),
        ]),
      if (_showForm)
        OpportunityForm(
          existing: _editing,
          onSave: _save,
          onCancel: () {
            setState(() {
              _showForm = false;
              _editing = null;
            });
          },
        ),
    ]);
  }

  @override
  Component build(BuildContext context) {
    return div(classes: 'admin-page', [
      if (_password == null) _buildLogin() else _buildDashboard(),
    ]);
  }
}

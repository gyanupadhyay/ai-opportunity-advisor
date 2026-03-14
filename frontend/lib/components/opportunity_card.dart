import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../models/opportunity.dart';

class OpportunityCard extends StatelessComponent {
  final Opportunity opportunity;

  const OpportunityCard({required this.opportunity, super.key});

  String _typeClass() {
    return switch (opportunity.type.toLowerCase()) {
      'scholarship' => 'scholarship',
      'internship' => 'internship',
      'fellowship' => 'fellowship',
      'summit' => 'summit',
      'exchange' => 'exchange',
      'research' => 'research',
      _ => 'scholarship',
    };
  }

  @override
  Component build(BuildContext context) {
    return div(classes: 'opportunity-card', [
      span(classes: 'card-type ${_typeClass()}', [
        .text(opportunity.type.toUpperCase()),
      ]),
      h4([.text(opportunity.title)]),
      div(classes: 'card-details', [
        if (opportunity.country.isNotEmpty)
          div(classes: 'card-detail', [
            .text('\u{1F4CD} ${opportunity.country}'),
          ]),
        if (opportunity.field.isNotEmpty)
          div(classes: 'card-detail', [
            .text('\u{1F4DA} ${opportunity.field}'),
          ]),
        if (opportunity.deadline.isNotEmpty)
          div(classes: 'card-detail', [
            .text('\u{1F4C5} Deadline: ${opportunity.deadline}'),
          ]),
        if (opportunity.description.isNotEmpty) div(classes: 'card-detail', [.text(opportunity.description)]),
      ]),
      if (opportunity.applicationLink.isNotEmpty)
        a(
          href: opportunity.applicationLink,
          classes: 'apply-btn',
          attributes: {'target': '_blank', 'rel': 'noopener noreferrer'},
          [.text('Apply Now \u{2192}')],
        ),
    ]);
  }
}

/** Informational patterns, not automatic prescriptions or a popularity ranking. */
export const dietStrategies = [
  {
    name: 'Mediterran / ausgewogene Mischkost',
    summary:
      'Viel Gemüse, Hülsenfrüchte, Vollkorn, Nüsse und pflanzliche Öle; je nach Vorliebe Fisch und Milchprodukte.',
    training:
      'Eine flexible Basis. Proteinquellen und Kohlenhydratmengen passend zum Training planen.',
    tradeoff: 'Die Lebensmittelauswahl legt weder Kalorien noch Protein automatisch fest.',
    url: 'https://www.heart.org/en/healthy-living/healthy-eating/eat-smart/nutrition-basics/mediterranean-diet',
    source: 'American Heart Association',
  },
  {
    name: 'Proteinbetont / Makros planen',
    summary:
      'Energie und Makronährstoffe werden bewusst geplant. Protein und Ballaststoffe können Mindestziele sein; Energie und Fett eher Bereiche.',
    training:
      'Protein auf Mahlzeiten verteilen. Die DGE nennt für Sport mit mehr als fünf Trainingsstunden pro Woche je nach Ziel 1,2–2,0 g/kg Körpergewicht pro Tag.',
    tradeoff:
      'Makroziele garantieren keine ausreichenden Mikronährstoffe. Kein pauschales Proteinziel für alle.',
    url: 'https://www.dge.de/presse/meldungen/2020/positionspapier-zur-proteinzufuhr-im-sport/',
    source: 'DGE, Positionspapier zur Proteinzufuhr im Sport',
  },
  {
    name: 'Energiedefizit / Gewichtsabnahme',
    summary:
      'Die längerfristige Energiezufuhr liegt unter dem Verbrauch. Verschiedene Essmuster können dafür geeignet sein.',
    training:
      'Krafttraining, ausreichendes Protein und ein alltagstauglicher Umfang helfen beim Erhalt von Muskelmasse.',
    tradeoff:
      'Ein großes Defizit kann Training und Erholung beeinträchtigen. Die App berechnet keinen medizinisch passenden Bedarf.',
    url: 'https://www.niddk.nih.gov/health-information/weight-management/healthy-eating-physical-activity-for-life',
    source: 'NIDDK',
  },
  {
    name: 'Erhaltung / Muskelaufbau',
    summary:
      'Erhaltung orientiert sich am längerfristigen Energiegleichgewicht. Muskelaufbau kombiniert progressives Training mit ausreichend Energie und Protein.',
    training:
      'Trainings- und Ruhetage können unterschiedliche Energie- oder Kohlenhydratziele haben. Erholung benötigt auch an freien Tagen Nährstoffe.',
    tradeoff:
      'Mehr Kalorien bedeuten nicht automatisch mehr Muskelmasse. Ziele anhand von Verlauf, Leistung und Erholung prüfen.',
    url: 'https://www.dge.de/presse/meldungen/2020/positionspapier-zur-proteinzufuhr-im-sport/',
    source: 'DGE, Sporternährung',
  },
  {
    name: 'Vegetarisch / pflanzenbetont / vegan',
    summary:
      'Vegetarisch lässt Fleisch und Fisch weg; vegan auch Eier, Milchprodukte und Honig. Tofu und Hülsenfrüchte sind gut planbare Proteinquellen.',
    training: 'Mehrere Proteinquellen kombinieren und die gesamte Tageszufuhr prüfen.',
    tradeoff:
      'Bei veganer Ernährung ist insbesondere eine zuverlässige Vitamin-B12-Versorgung wichtig. Die Makroanpassung prüft keine vollständige Mikronährstoffversorgung.',
    url: 'https://www.dge.de/gesunde-ernaehrung/faq/faqs-vegane-ernaehrung/',
    source: 'DGE, vegane Ernährung',
  },
  {
    name: 'Low Carb / ketogen',
    summary:
      'Kohlenhydrate werden begrenzt; ketogene Varianten sind deutlich strenger. Für „Low Carb“ gibt es keine einheitliche Grenze.',
    training:
      'Hohe Trainingsintensitäten können von verfügbaren Kohlenhydraten profitieren. Die Verträglichkeit ist individuell.',
    tradeoff:
      'Kein automatischer Vorteil unabhängig von Energiezufuhr und Umsetzung. Ein niedriger Kohlenhydratwert beweist keine Ketose; Ballaststoffe und Lebensmittelqualität beachten.',
    url: 'https://register.awmf.org/assets/guidelines/050-001l_S3_Praevention-Therapie-Adipositas_2024-10.pdf',
    source: 'S3-Leitlinie Adipositas, 2024',
  },
  {
    name: 'Intervallfasten / zeitbegrenztes Essen',
    summary:
      'Begrenzt Essenszeiten statt zwingend bestimmte Lebensmittel. Energie und Nährstoffmengen bleiben wichtig.',
    training:
      'Essensfenster so wählen, dass Training, Proteinverteilung und Erholung praktisch möglich bleiben.',
    tradeoff:
      'Die Cochrane-Auswertung 2026 fand bei Erwachsenen mit Übergewicht/Adipositas wenig bis keinen Unterschied zur üblichen Ernährungsberatung beim Gewichtsverlust. Keine Aussage über Muskelaufbau daraus ableiten.',
    url: 'https://doi.org/10.1002/14651858.CD015610.pub2',
    source: 'Cochrane Review, 2026',
  },
  {
    name: 'DASH',
    summary:
      'Gemüse, Obst, Vollkorn, Hülsenfrüchte und unter anderem fettarme Milchprodukte; begrenzt Natrium und gesättigte Fette.',
    training:
      'Kann eine ausgewogene Grundlage sein, benötigt aber eigene Energie- und Proteinziele.',
    tradeoff:
      'Die Portionenanpassung berücksichtigt derzeit weder Natriumgrenzen noch medizinische Anforderungen. Ein DASH-konformer Plan wird dadurch nicht garantiert.',
    url: 'https://www.nhlbi.nih.gov/health/dash-eating-plan',
    source: 'NHLBI',
  },
] as const;
export const strategyReviewedOn = '2026-11-19';

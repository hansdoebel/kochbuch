#let data = json("shopping-list.json")
#set page(width: 108mm, height: 192mm, margin: (x: 8mm, y: 10mm), footer: context align(right, text(size: 8pt, fill: gray, counter(page).display("1"))))
#set text(font: "Libertinus Serif", size: 12pt, lang: "de")
#set par(leading: 0.55em)
#set heading(numbering: none)
#text(size: 9pt, fill: rgb("326d50"), weight: "bold")[KOCHBUCH / ZUM MITNEHMEN]
#v(3mm)
#text(size: 24pt, weight: "bold")[Einkaufsliste]
#v(2mm)
#text(size: 10pt, fill: gray)[#data.recipes.len() Rezepte · #data.itemCount Einträge]
#line(length: 100%, stroke: 0.5pt + rgb("dce4de"))
#for recipe in data.recipes [
  #let label = text(size: 10pt)[#recipe.title · #recipe.portions]
  #if recipe.sourceUrl != none { link(recipe.sourceUrl, label) } else { label } \
]
#if data.unscaledRecipes.len() > 0 [
  #v(2mm)
  #text(size: 10pt, fill: rgb("8c5e24"))[Archivrezepte behalten ihre Originalmengen. Diese Zutaten sind separat aufgeführt.]
]
#for group in data.groups [
  #heading(level: 2, text(size: 13pt, fill: rgb("326d50"), group.name))
  #for item in group.items [
    #block(breakable: false, above: 1.5mm, below: 1.5mm)[
      #grid(columns: (4mm, 1fr), column-gutter: 1mm,
        rect(width: 3mm, height: 3mm, radius: 0.4mm, stroke: 0.6pt + gray),
        text(item.text),
      )
    ]
  ]
]

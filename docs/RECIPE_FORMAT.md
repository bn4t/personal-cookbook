# `recipes.json` format

Recipes live in [`PersonalCookbook/Resources/recipes.json`](../PersonalCookbook/Resources/recipes.json) and are decoded with Swift `Codable` (see [`Models.swift`](../PersonalCookbook/Models/Models.swift)). No backend or network is involved — edit this file (or use the in-app **JSON Debug** screen) to add your own recipes.

The top level is a **JSON array of `Recipe` objects**:

```json
[
  { "id": "...", "name": "...", ... },
  { "id": "...", "name": "...", ... }
]
```

Decoding is **tolerant**: only `id` and `name` are truly required. Every other field may be omitted and falls back to the default listed below, so older recipes keep working as the format grows. The JSON Debug screen reports precise, location-aware errors when something is malformed.

---

## `Recipe`

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `id` | string | **yes** | — | Unique, stable identifier (a slug works well, e.g. `"sweet-potato-chickpea-curry"`). |
| `name` | string | **yes** | — | Display name. |
| `description` | string | no | `""` | One-line summary shown on the card and detail header. |
| `whyCookThis` | string | no | `""` | Short "why" blurb shown in the Overview tab. |
| `category` | string | no | `"Other"` | Free-form (e.g. `"Dinner"`, `"Breakfast"`, `"Lunch"`); drives the category filter. |
| `prepTimeMinutes` | int | no | `0` | Prep minutes. |
| `cookTimeMinutes` | int | no | `0` | Cook minutes. Total time = prep + cook (computed). |
| `servings` | int | no | `1` | Base servings; the basis for ingredient scaling. |
| `difficulty` | enum | no | `"easy"` | One of `easy`, `medium`, `hard`. |
| `energyLevel` | enum | no | `"medium"` | One of `low`, `medium`, `high`. The "Low energy" filter matches `low`. |
| `batchFriendly` | bool | no | `false` | Drives the "Batch" badge/filter. |
| `vegetarian` | bool | no | `false` | Drives the "Vegetarian" badge/filter. |
| `highProtein` | bool | no | `false` | Drives the "High protein" badge/filter. |
| `tags` | string[] | no | `[]` | Searchable free-form tags. |
| `ingredientGroups` | `IngredientGroup`[] | no | `[]` | Grouped ingredient lists (see below). |
| `steps` | `CookingStep`[] | no | `[]` | Ordered steps; powers Cooking Mode. Empty disables "Start Cooking". |
| `tasteFixes` | `TasteFix`[] | no | `[]` | "If it tastes X, do Y" pairs (Notes tab + completion screen). |
| `easyUpgrades` | string[] | no | `[]` | Optional ways to level the dish up (Notes tab). |
| `batchNotes` | string | no | `""` | Storage / leftovers guidance (Notes tab). |
| `safetyNotes` | string[] | no | `[]` | Food-safety reminders (Notes tab). |

## `IngredientGroup`

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes | Group heading, e.g. `"Sauce"`. If a recipe has a single group named `"Ingredients"`, the heading is hidden. |
| `ingredients` | `Ingredient`[] | yes | The items in this group. |

## `Ingredient`

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `name` | string | **yes** | — | Ingredient name. |
| `amount` | number \| null | no | `null` | Numeric quantity. **Scales** with servings. Use `null` for non-quantified items (then `unit` carries the text, e.g. `"to taste"`). |
| `unit` | string \| null | no | `null` | Unit, e.g. `"g"`, `"tbsp"`, `"cloves"`. When `amount` is `null`, this is shown alone (e.g. `"to taste"`, `"to serve"`). |
| `note` | string \| null | no | `null` | Prep note, e.g. `"minced"`, `"drained and rinsed"`. |
| `optional` | bool | no | `false` | Shows an "optional" tag. |
| `shoppingCategory` | enum | no | `"Other"` | Aisle for the shopping list. One of `Produce`, `Protein`, `Pantry`, `Dairy`, `Frozen`, `Spices`, `Other`. |

**Scaling & shopping behaviour**
- Amounts are multiplied by `targetServings / servings`. Items with `amount: null` are never scaled.
- In the shopping list, identical items (same `name` + `unit`, case-insensitive) are **merged** and their amounts summed. Different units stay as separate lines.
- Items are grouped under their `shoppingCategory` in a fixed aisle order: Produce → Protein → Pantry → Dairy → Frozen → Spices → Other.

## `CookingStep`

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `title` | string | **yes** | — | Big step title in Cooking Mode. |
| `instruction` | string | no | `""` | Short instruction body. |
| `durationMinutes` | int \| null | no | `null` | If present, the step shows a built-in countdown **timer**. |
| `ingredients` | string[] | no | `[]` | Ingredient names relevant to this step (shown as chips). Free-form strings — they don't have to match `Ingredient.name` exactly. |
| `tips` | string[] | no | `[]` | Per-step tips. |

## `TasteFix`

| Field | Type | Required | Notes |
|---|---|---|---|
| `problem` | string | yes | e.g. `"Tastes flat"`. |
| `fix` | string | yes | e.g. `"Add salt or a splash more soy sauce."`. |

---

## Minimal example

```json
[
  {
    "id": "greek-yogurt-bowl",
    "name": "Greek Yogurt Bowl",
    "servings": 1
  }
]
```

## Full example

```json
[
  {
    "id": "sweet-potato-chickpea-curry",
    "name": "Sweet Potato Chickpea Curry",
    "description": "The forgiving one-pot. Warm, cozy, and hard to fully ruin.",
    "whyCookThis": "When you want something comforting with almost no technique.",
    "category": "Dinner",
    "prepTimeMinutes": 10,
    "cookTimeMinutes": 30,
    "servings": 3,
    "difficulty": "easy",
    "energyLevel": "low",
    "batchFriendly": true,
    "vegetarian": true,
    "highProtein": false,
    "tags": ["one-pot", "cozy", "freezer-friendly"],
    "ingredientGroups": [
      {
        "name": "Pot",
        "ingredients": [
          { "name": "Sweet potato", "amount": 400, "unit": "g", "note": "peeled and diced", "optional": false, "shoppingCategory": "Produce" },
          { "name": "Chickpeas", "amount": 1, "unit": "can", "note": "drained and rinsed", "optional": false, "shoppingCategory": "Pantry" },
          { "name": "Light coconut milk", "amount": 400, "unit": "ml", "optional": false, "shoppingCategory": "Pantry" },
          { "name": "Salt", "amount": null, "unit": "to taste", "optional": false, "shoppingCategory": "Spices" }
        ]
      }
    ],
    "steps": [
      {
        "title": "Simmer",
        "instruction": "Add everything and simmer until the sweet potato is soft.",
        "durationMinutes": 22,
        "ingredients": ["Sweet potato", "Chickpeas", "Light coconut milk"],
        "tips": ["Stir occasionally so nothing catches on the bottom."]
      }
    ],
    "tasteFixes": [
      { "problem": "Too thin", "fix": "Simmer uncovered for 5-10 minutes." }
    ],
    "easyUpgrades": ["Add chicken.", "Stir in red lentils."],
    "batchNotes": "Good for 3-4 days and freezes well. Store rice separately.",
    "safetyNotes": ["Reheat until hot all the way through."]
  }
]
```

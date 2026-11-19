INSERT INTO ingredient_nutrition_matches (ingredient_id,food_id,method,reviewed_on,note)
SELECT json_extract(value,'$.ingredient_id'),json_extract(value,'$.food_id'),json_extract(value,'$.method'),json_extract(value,'$.reviewed_on'),json_extract(value,'$.note') FROM json_each($document,'$.matches');
INSERT INTO recipe_nutrition_weights (recipe_ingredient_id,edible_grams,source_url,reviewed_on,note)
SELECT json_extract(value,'$.recipe_ingredient_id'),json_extract(value,'$.edible_grams'),json_extract(value,'$.source_url'),json_extract(value,'$.reviewed_on'),json_extract(value,'$.note') FROM json_each($document,'$.weights');

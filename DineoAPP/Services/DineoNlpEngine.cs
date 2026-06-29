using System.Text;
using DineoAPP.Models;

namespace DineoAPP.Services
{
    public class QueryIntent
    {
        public List<string> CuisineKeywords { get; set; } = new();
        public string Budget { get; set; } = "any";      // "ieftin" | "lux" | "any"
        public string Occasion { get; set; } = "any";    // "romantic" | "familie" | "prieteni" | "any"
        public List<string> WantedFeatures { get; set; } = new(); // "terrace" | "bar" | "stage"
    }

    public static class DineoNlpEngine
    {
        // ── Keyword dictionaries ──────────────────────────────────────────────

        private static readonly Dictionary<string, List<string>> CuisineKeywords = new()
        {
            ["italian"]       = new() { "italian", "italiana", "pizza", "paste", "spaghetti", "lasagna", "risotto", "bruschetta", "trattoria", "carbonara", "tiramisu", "italian" },
            ["romanesc"]      = new() { "romanesc", "romaneasca", "traditional", "traditionala", "ciorba", "sarmale", "mici", "mamaliga", "tochitura", "specific", "romanesti", "tara" },
            ["japonez"]       = new() { "japonez", "japoneza", "sushi", "ramen", "maki", "nigiri", "sashimi", "tempura", "wasabi", "asiatic", "asiatica", "noodles" },
            ["burger"]        = new() { "burger", "hamburger", "american", "americana", "cheeseburger", "fastfood", "fast", "wings", "fries" },
            ["grill"]         = new() { "grill", "gratar", "steak", "carne", "vita", "miel", "ribbs", "coaste", "carnivora", "bbq", "barbeque" },
            ["bar"]           = new() { "pub", "bere", "bar", "cocktail", "drinks", "bauturi", "shots" },
            ["french"]        = new() { "francez", "franceza", "bistro", "bistrou", "vin", "croissant", "crepe" },
            ["tapas"]         = new() { "tapas", "spaniol", "spaniola", "tapas", "aperitive" },
            ["international"] = new() { "international", "internationala", "fusion", "modern", "moderna", "contemporan", "variat", "divers" },
        };

        private static readonly List<string> RomanticKeywords = new()
        {
            "romantic", "romantica", "cuplu", "doi", "aniversare", "valentine", "seara", "speciala", "special", "intalnire", "date", "dragobete"
        };

        private static readonly List<string> FamilyKeywords = new()
        {
            "familie", "familial", "copii", "copil", "bunici", "parinti", "multi", "mare", "petrecere", "zi de nastere", "birthday", "aniversare de familie"
        };

        private static readonly List<string> FriendsKeywords = new()
        {
            "prieteni", "grup", "iesire", "chill", "relaxat", "casual", "distractie", "seara cu prietenii", "socializare"
        };

        private static readonly List<string> CheapKeywords = new()
        {
            "ieftin", "ieftina", "accesibil", "accesibila", "buget", "economic", "economica", "rezonabil", "rezonabila", "nu prea scump", "moderat"
        };

        private static readonly List<string> LuxuryKeywords = new()
        {
            "scump", "lux", "luxos", "luxoasa", "elegant", "eleganta", "exclusiv", "exclusiva", "fine dining", "premium", "high-end", "sofisticat", "deosebit"
        };

        private static readonly Dictionary<string, List<string>> FeatureKeywords = new()
        {
            ["terrace"] = new() { "terasa", "aer liber", "afara", "exterior", "gradina", "outdoor", "vara" },
            ["stage"]   = new() { "muzica", "muzica live", "concert", "show", "live", "entertainment", "band", "distractie", "petrecere" },
            ["bar"]     = new() { "bar", "cocktail", "bauturi", "drinks", "bere", "cocktailuri" },
        };

        // ── Tokenizer ─────────────────────────────────────────────────────────

        public static List<string> Tokenize(string input)
        {
            return input.ToLower()
                .Replace(",", " ").Replace(".", " ").Replace("!", " ").Replace("?", " ")
                .Replace("-", " ").Replace("ș", "s").Replace("ț", "t")
                .Replace("ă", "a").Replace("â", "a").Replace("î", "i")
                .Split(' ', StringSplitOptions.RemoveEmptyEntries)
                .ToList();
        }

        // ── Intent extraction ─────────────────────────────────────────────────

        public static QueryIntent ExtractIntent(List<string> tokens)
        {
            var intent = new QueryIntent();
            var joined = string.Join(" ", tokens);

            // Cuisine
            foreach (var (cuisineKey, keywords) in CuisineKeywords)
                if (keywords.Any(k => tokens.Contains(k) || joined.Contains(k)))
                    intent.CuisineKeywords.Add(cuisineKey);

            // Budget
            if (CheapKeywords.Any(k => tokens.Contains(k) || joined.Contains(k)))
                intent.Budget = "ieftin";
            else if (LuxuryKeywords.Any(k => tokens.Contains(k) || joined.Contains(k)))
                intent.Budget = "lux";

            // Occasion
            if (RomanticKeywords.Any(k => tokens.Contains(k) || joined.Contains(k)))
                intent.Occasion = "romantic";
            else if (FamilyKeywords.Any(k => tokens.Contains(k) || joined.Contains(k)))
                intent.Occasion = "familie";
            else if (FriendsKeywords.Any(k => tokens.Contains(k) || joined.Contains(k)))
                intent.Occasion = "prieteni";

            // Features
            foreach (var (featureKey, keywords) in FeatureKeywords)
                if (keywords.Any(k => tokens.Contains(k) || joined.Contains(k)))
                    intent.WantedFeatures.Add(featureKey);

            return intent;
        }

        // Maps intent keys → English DB CuisineType values (what's actually stored in the DB)
        private static readonly Dictionary<string, List<string>> DbCuisineMatchers = new()
        {
            ["italian"]       = new() { "italian" },
            ["romanesc"]      = new() { "romanian", "roman" },
            ["japonez"]       = new() { "japanese", "japonez" },
            ["burger"]        = new() { "american", "burger" },
            ["grill"]         = new() { "grill", "steak", "bbq", "barbeque" },
            ["bar"]           = new() { "pub", "pub food", "bar food" },
            ["french"]        = new() { "french", "francez" },
            ["tapas"]         = new() { "spanish", "tapas" },
            ["international"] = new() { "international", "fusion", "mediterranean", "seafood", "indian", "modern" },
        };

        // ── Scoring ───────────────────────────────────────────────────────────

        public static double ScoreRestaurant(
            Restaurant r,
            List<FloorDecor> decors,
            List<MenuCategory> menuCategories,
            List<string> queryTokens,
            QueryIntent intent)
        {
            double score = 0;
            var cuisine = (r.CuisineType ?? "").ToLower()
                .Replace("ș", "s").Replace("ț", "t").Replace("ă", "a").Replace("â", "a").Replace("î", "i");

            // 1. Cuisine match — biggest weight
            bool cuisineMatched = false;
            if (intent.CuisineKeywords.Any())
            {
                foreach (var key in intent.CuisineKeywords)
                {
                    var dbValues = DbCuisineMatchers.GetValueOrDefault(key, new List<string> { key });
                    if (dbValues.Any(v => cuisine.Contains(v)))
                    {
                        score += 5.0;
                        cuisineMatched = true;
                        break;
                    }
                }
            }
            else
            {
                // No cuisine preference — everyone gets a base score so we always return results
                score += 1.0;
            }

            // 2. Menu keyword search — only for restaurants that did NOT match on cuisine type,
            //    so specialists always rank above restaurants that just happen to have the item.
            if (!cuisineMatched && queryTokens.Any())
            {
                double menuBonus = 0;
                foreach (var cat in menuCategories)
                {
                    var catName = Normalize(cat.Name ?? "");
                    if (queryTokens.Any(t => t.Length >= 3 && catName.Contains(t)))
                        menuBonus += 1.5;

                    foreach (var item in cat.MenuItems ?? new List<MenuItem>())
                    {
                        var itemName = Normalize(item.Name ?? "");
                        var itemDesc = Normalize(item.Description ?? "");
                        if (queryTokens.Any(t => t.Length >= 3 && (itemName.Contains(t) || itemDesc.Contains(t))))
                            menuBonus += 0.5;
                    }
                }
                // Cap at 3.5 so even the best menu match still scores below a cuisine-type specialist
                score += Math.Min(menuBonus, 3.5);
            }

            // 3. Budget match
            if (intent.Budget == "lux")
            {
                if (r.Rating >= 4.5) score += 3.0;
                else if (r.Rating >= 4.0) score += 1.5;
                else score -= 2.0;
            }
            else if (intent.Budget == "ieftin")
            {
                if (r.Rating <= 3.8) score += 2.0;
                else if (r.Rating <= 4.3) score += 1.0;
            }

            // 4. Occasion match
            if (intent.Occasion == "romantic")
            {
                score += r.Rating >= 4.3 ? 2.0 : 0.5;
            }
            else if (intent.Occasion == "familie")
            {
                if (decors.Any() || r.Rating >= 3.5) score += 1.5;
            }
            else if (intent.Occasion == "prieteni")
            {
                score += 1.0;
            }

            // 5. Decor feature match
            foreach (var feature in intent.WantedFeatures)
            {
                if (decors.Any(d => d.Type == feature))
                    score += 2.0;
            }

            // 6. Base rating bonus (always)
            score += r.Rating * 0.3;

            return score;
        }

        private static string Normalize(string s) =>
            s.ToLower()
             .Replace("ș", "s").Replace("ț", "t")
             .Replace("ă", "a").Replace("â", "a").Replace("î", "i");

        // ── Per-restaurant reason text ────────────────────────────────────────

        public static string BuildRestaurantReason(
            Restaurant r,
            QueryIntent intent,
            List<string> menuMatchedTerms)
        {
            var lines = new List<string>();

            var cuisine = (r.CuisineType ?? "").ToLower();
            if (cuisine.Contains("italian")) lines.Add("bucătărie italiană autentică");
            else if (cuisine.Contains("roman")) lines.Add("bucătărie românească tradițională");
            else if (cuisine.Contains("japon") || cuisine.Contains("sushi")) lines.Add("preparate japoneze și sushi proaspăt");
            else if (cuisine.Contains("burger") || cuisine.Contains("american")) lines.Add("burger-uri artizanale și specialități americane");
            else if (cuisine.Contains("grill") || cuisine.Contains("steak") || cuisine.Contains("carne")) lines.Add("specialități la grătar și carne de calitate");
            else if (cuisine.Contains("pub") || cuisine.Contains("bere")) lines.Add("specific de pub cu băuturi și mâncare tradițională");
            else if (cuisine.Contains("tapas")) lines.Add("tapas și preparate spaniole");
            else if (cuisine.Contains("french") || cuisine.Contains("francez")) lines.Add("bucătărie franceză rafinată");
            else if (!string.IsNullOrWhiteSpace(r.CuisineType)) lines.Add($"specific {r.CuisineType.ToLower()}");

            if (menuMatchedTerms.Any())
            {
                var termList = string.Join(", ", menuMatchedTerms.Distinct().Take(3));
                lines.Add($"are în meniu preparate de tip {termList}");
            }

            if (intent.Occasion == "romantic") lines.Add("atmosferă perfectă pentru o seară romantică");
            else if (intent.Occasion == "familie") lines.Add("spațiu primitor pentru familie");
            else if (intent.Occasion == "prieteni") lines.Add("ideal pentru o ieșire cu prietenii");

            if (intent.Budget == "lux" && r.Rating >= 4.5) lines.Add("experiență premium");
            else if (intent.Budget == "ieftin") lines.Add("prețuri accesibile");

            if (lines.Any())
            {
                var desc = string.Join(", ", lines);
                return char.ToUpper(desc[0]) + desc[1..] + ".";
            }

            if (!string.IsNullOrWhiteSpace(r.Description))
                return r.Description.Length > 100 ? r.Description[..100] + "…" : r.Description;

            return string.Empty;
        }

        public static string BuildIntro(bool noMatch) =>
            noMatch
                ? "No exact match found, but here are our top rated restaurants:"
                : "Here are our recommendations for you:";
    }
}

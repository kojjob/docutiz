SitemapGenerator::Sitemap.default_host = "https://yourapp.com"

SitemapGenerator::Sitemap.create do
  add root_path, priority: 1.0, changefreq: 'weekly'
  add pricing_path, priority: 0.8, changefreq: 'monthly'
  add features_path, priority: 0.8, changefreq: 'monthly'
  add about_path, priority: 0.6, changefreq: 'monthly'
end
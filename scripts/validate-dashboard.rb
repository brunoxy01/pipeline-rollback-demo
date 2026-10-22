#!/usr/bin/env ruby
# Executa cada query do dashboard no tenant, simulando a substituicao de $App (valor ja entre aspas).
require "yaml"
require "open3"

file = ARGV[0] || "dynatrace/dashboard.yaml"
app = ARGV[1] || "demo-app"
dash = YAML.load_file(file)["content"]
failed = 0

queries = dash["variables"].map { |v| ["variavel #{v['key']}", v["input"]] }
queries += dash["tiles"].sort_by { |k, _| k.to_i }.select { |_, t| t["type"] == "data" }.map { |_, t| [t["title"], t["query"]] }

queries.each do |title, q|
  q = q.gsub("$App", "\"#{app}\"")
  out, st = Open3.capture2e("dtctl", "query", q, "-o", "csv")
  lines = out.strip.lines
  bad = !st.success? || out.include?("isn't allowed") || out.include?("\"ok\": false") || out.include?("error")
  rows = bad ? 0 : [lines.length - 1, 0].max
  failed += 1 if bad
  puts "#{bad ? 'FALHOU' : 'ok    '} | #{rows} linhas | #{title}"
  puts "   #{lines.first(3).join('   ').strip[0, 220]}" if bad || rows == 0
end
puts failed.zero? ? "\nTodas as queries executaram." : "\n#{failed} query(s) com erro."
exit(failed.zero? ? 0 : 1)

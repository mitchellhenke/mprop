defmodule Properties.Indexer do
  @type gram_map :: %{optional(String.t()) => MapSet.t()}
  @type search_results :: list({String.t(), float()})

  @gram_map File.read!("./priv/data/street_names_list.txt")
            |> String.split("\n", trim: true)
            |> Enum.reduce(%{}, fn word, map ->
              word = String.upcase(word)

              graphemes =
                String.graphemes("  #{word}  ")
                |> Enum.map(&String.trim/1)
                |> Enum.reject(&(&1 == ""))

              trigrams = Enum.chunk_every(graphemes, 3, 1)

              trigrams
              |> Enum.uniq()
              |> Enum.reduce(map, fn gram, map ->
                Map.update(map, gram, MapSet.new([word]), fn set -> MapSet.put(set, word) end)
              end)
            end)

  @spec search(String.t()) :: search_results
  def search(word) do
    search(word, @gram_map)
  end

  @spec search(String.t(), gram_map) :: search_results
  def search(word, gram_map) do
    grams = build_grams(word)

    Enum.reduce(grams, MapSet.new(), fn gram, set ->
      Map.get(gram_map, gram, [])
      |> MapSet.new()
      |> MapSet.union(set)
    end)
    |> Enum.map(fn match ->
      {match, String.jaro_distance(match, word)}
    end)
    |> Enum.sort(fn {_word, score}, {_word2, score2} ->
      score >= score2
    end)
  end

  @spec build_grams(String.t()) :: list(String.t())
  def build_grams(word) do
    word = String.upcase(word)

    graphemes =
      String.graphemes("  #{word}  ")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    trigrams = Enum.chunk_every(graphemes, 3, 1)

    trigrams
    |> Enum.uniq()
  end
end

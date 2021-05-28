import Ecto.Query

content =
  from(a in Properties.Assessment,
    where: a.year == 2017 and not is_nil(a.street),
    select: a.street,
    distinct: true
  )
  |> Properties.Repo.all()
  |> Enum.join("\n")

File.write!("./priv/data/street_names_list.txt", content)

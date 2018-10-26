defmodule Properties.SaleTest do
  use Properties.ModelCase

  alias Properties.Sale

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Sale.changeset(%Sale{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Sale.changeset(%Sale{}, @invalid_attrs)
    refute changeset.valid?
  end
end

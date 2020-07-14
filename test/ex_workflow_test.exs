defmodule ExWorkflowTest do
  use ExUnit.Case, async: true
  import Ecto.Changeset

  defmodule Article do
    use Ecto.Schema
    import ExWorkflow
  
    schema "articles" do
      field :state, :string
    end
  
    workflow do
      "unpublished" ~> :publish ~> "published"
      "published" ~> :unpublish ~> "unpublished"
      "unpublished" ~> :trash ~> "trashed_unpublished"
      "published" ~> :trash ~> "trashed_published"
      "trashed_unpublished" ~> :recycle ~> "unpublished"
      "trashed_published" ~> :recycle ~> "published"
    end

    def recycle(changeset) do
      changeset
    end

    def recycle(changeset, use_original: true) do
      super(changeset, [])
    end
  end

  alias ExWorkflowTest.Article

  setup_all do
    [changeset: cast(%Article{state: "unpublished"}, %{}, [:state])]
  end

  test "transitions", %{changeset: changeset} do
    changeset = Article.publish(changeset)
    assert get_field(changeset, :state) == "published"

    changeset = Article.unpublish(changeset)
    assert get_field(changeset, :state) == "unpublished"
  end

  test "same event for different states", %{changeset: changeset} do
    c1 = Article.trash(changeset)
    assert get_field(c1, :state) == "trashed_unpublished"

    c2 = changeset |> Article.publish() |> Article.trash()
    assert get_field(c2, :state) == "trashed_published"
  end

  test "event override", %{changeset: changeset} do
    changeset = Article.trash(changeset)
    assert changeset |> Article.recycle() |> get_field(:state) == "trashed_unpublished"
    assert changeset |> Article.recycle(use_original: true) |> get_field(:state) == "unpublished"
  end

  test "event on wrong state", %{changeset: changeset} do
    changeset = changeset |> Article.trash(use_original: true) |> Article.publish()
    assert not changeset.valid?
    assert changeset.errors[:state] == {"event_unavailable", [state: "trashed_unpublished", event: :publish]}
  end
end

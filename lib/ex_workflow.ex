defmodule ExWorkflow do
  @moduledoc """
  A minimal workflow implementation for Ecto schemas.
  Inspired by Ruby's [geekq/workflow](https://github.com/geekq/workflow).

  ## Usage

  By importing `ExWorkflow` into your Ecto schema module,
  you can define your workflow in the format of

  ```
  workflow do
    state ~> event ~> new_state
    ...
  end
  ```

  The default state field is `state`. 
  If you want to use a custom field to store the states,
  you can pass `state_field: <custom state field name>` to the `workflow` macro:

  ```
  workflow state_field: :my_state do
    ...
  end
  ```

  ## Example

  ```
  defmodule Article do
    use Ecto.Schema
    import ExWorkflow
    import Ecto.Changeset
  
    schema "articles" do
      field :state, :string
    end
  
    workflow do
      # state ~> event ~> new_state
      "unpublished" ~> :publish ~> "published"
      "published" ~> :unpublish ~> "unpublished"
      "unpublished" ~> :trash ~> "trashed_unpublished"
      "published" ~> :trash ~> "trashed_published"
      "trashed_unpublished" ~> :recycle ~> "unpublished"
      "trashed_published" ~> :recycle ~> "published"
    end

    # You can override the event :publish. It should return a changeset.
    # The `super` keyword is also available.
    def publish(changeset) do
      # Do something interesting
      super(changeset)
    end

    # You can also pass 1 additional argument of any type.
    def publish(changeset, discard_draft: true) do
      ...
    end
  end
  ```

  Each event gives 2 functions named after the event,
  for example, the `:publish` event, gives `publish(changeset)` and `publish(changeset, addtional_arg)`.
  The additional argument is by default ignored, but you can override it.

  ```
  changeset = %Article{} 
              |> Ecto.Changeset.cast(%Article{state: "unpublished"}, %{}, [:state])
              |> Article.publish()
  
  Ecto.Changeset.get_field(changeset, :state)  #=> "published"

  changeset = Article.trash(changeset)
  Ecto.Changeset.get_field(changeset, :state)  #=> "trashed_published"

  changeset = Article.recycle(changeset)
  Ecto.Changeset.get_field(changeset, :state)  #=> "published"
  ```

  ## TODO
  - Workflow specification API
  - Draw workflow diagram
  """

  defmacro workflow(do: transitions) do
    _workflow(:state, transitions)
  end

  defmacro workflow(state_field: state_field, do: transitions) do
    _workflow(state_field, transitions)
  end

  defp _workflow(state_field, {:__block__, _, transitions}) do
    asts = transitions
           |> Enum.group_by(&event/1)
           |> Enum.flat_map(&def_event(&1, state_field))
    {:__block__, [], asts}
  end

  defp _workflow(state_field, transition) do
    _workflow(state_field, {:__block__, [], [transition]})
  end

  defp event({:~>, _, [{:~>, _, [_from_state, event]}, _to_state]}), do: event

  defp states({:~>, _, [{:~>, _, [from_state, _event]}, to_state]}) do
    {from_state, to_state}
  end

  defp def_event({event, transitions}, state_field) do
    [
      [def_event_declaration(event)],
      def_event_for_changed_state(event, transitions, state_field),
      [def_event_failover_for_changed_state(event, state_field)],
      def_event_for_unchanged_state(event, transitions, state_field),
      [def_event_failover_for_unchanged_state(event, state_field)],
      [def_event_overridable(event)]
    ] |> Enum.flat_map(& &1)
  end

  defp def_event_declaration(event) do
    quote location: :keep do
      def unquote(event)(changeset, options \\ [])
    end
  end

  defp def_event_for_changed_state(event, transitions, state_field) do
    transitions
    |> Enum.map(&states/1)
    |> Enum.map(&def_transition_for_changed_state(event, elem(&1, 0), elem(&1, 1), state_field))
  end

  defp def_event_for_unchanged_state(event, transitions, state_field) do
    transitions
    |> Enum.map(&states/1)
    |> Enum.map(&def_transition_for_unchanged_state(event, elem(&1, 0), elem(&1, 1), state_field))
  end

  defp def_transition_for_changed_state(event, from_state, to_state, state_field) do
    quote location: :keep do
      def unquote(event)(
        %Ecto.Changeset{
          data: %__MODULE__{},
          changes: %{unquote(state_field) => unquote(from_state)}
        } = changeset,
        _opts
      ) do
        Ecto.Changeset.put_change(changeset, unquote(state_field), unquote(to_state))
      end
    end
  end

  defp def_event_failover_for_changed_state(event, state_field) do
    quote location: :keep do
      def unquote(event)(
        %Ecto.Changeset{
          changes: %{unquote(state_field) => current_state}
        } = changeset,
        _opts
      ) do
        Ecto.Changeset.add_error(changeset, unquote(state_field), 
          "event_unavailable", state: current_state, event: unquote(event))
      end
    end
  end

  defp def_transition_for_unchanged_state(event, from_state, to_state, state_field) do
    quote location: :keep do
      def unquote(event)(
        %Ecto.Changeset{
          data: %__MODULE__{unquote(state_field) => unquote(from_state)},
        } = changeset,
        _opts
      ) do
        Ecto.Changeset.put_change(changeset, unquote(state_field), unquote(to_state))
      end
    end
  end

  defp def_event_failover_for_unchanged_state(event, state_field) do
    quote location: :keep do
      def unquote(event)(
        %Ecto.Changeset{
          data: %__MODULE__{unquote(state_field) => current_state}
        } = changeset,
        _opts
      ) do
        Ecto.Changeset.add_error(changeset, unquote(state_field), 
          "event_unavailable", state: current_state, event: unquote(event))
      end
    end
  end

  defp def_event_overridable(event) do
    quote location: :keep, bind_quoted: [event: event] do
      defoverridable [{event, 1}, {event, 2}]
    end
  end
end


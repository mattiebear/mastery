defmodule Mastery.Boundary.QuizManager do
  use GenServer

  alias Mastery.Core.Quiz

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, %{}, options)
  end

  @impl GenServer
  def init(quizzes) when is_map(quizzes) do
    {:ok, quizzes}
  end

  @impl GenServer
  def init(_quizzes), do: {:error, "quizzes must be a map"}

  @impl GenServer
  def handle_call({:build_quiz, quiz_fields}, _from, quizzes) do
    quiz = Quiz.new(quiz_fields)
    new_quizzes = Map.put(quizzes, quiz.title, quiz)
    {:reply, :ok, new_quizzes}
  end

  @impl GenServer
  def handle_call({:add_template, quiz_title, template_fields}, _from, quizzes) do
    new_quizzes =
      Map.update!(quizzes, quiz_title, fn quiz -> Quiz.add_template(quiz, template_fields) end)

    {:reply, :ok, new_quizzes}
  end

  @impl GenServer
  def handle_call({:lookup_quiz_by_title, title}, _from, quizzes) do
    {:reply, quizzes[title], quizzes}
  end

  @impl GenServer
  def handle_call({:remove_quiz, quiz_title}, _from, quizzes) do
    new_quizzes = Map.delete(quizzes, quiz_title)
    {:reply, :ok, new_quizzes}
  end

  def build_quiz(quiz_fields) do
    GenServer.call(__MODULE__, {:build_quiz, quiz_fields})
  end

  def add_template(quiz_title, template_fields) do
    GenServer.call(__MODULE__, {:add_template, quiz_title, template_fields})
  end

  def lookup_quiz_by_title(title) do
    GenServer.call(__MODULE__, {:lookup_quiz_by_title, title})
  end

  def remove_quiz(manager \\ __MODULE__, quiz_title) do
    GenServer.call(manager, {:remove_quiz, quiz_title})
  end
end

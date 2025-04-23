defmodule Mastery.Boundary.QuizManager do
  use GenServer

  alias Mastery.Core.Quiz

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

  def build_quiz(manager \\ __MODULE__, quiz_fields) do
    GenServer.call(manager, {:build_quiz, quiz_fields})
  end

  def add_template(manager \\ __MODULE__, quiz_title, template_fields) do
    GenServer.call(manager, {:add_template, quiz_title, template_fields})
  end

  def lookup_quiz_by_title(manager \\ __MODULE__, title) do
    GenServer.call(manager, {:lookup_quiz_by_title, title})
  end
end

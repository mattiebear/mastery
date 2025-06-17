defmodule Mastery.Boundary.QuizSession do
  use GenServer

  alias Mastery.Core.{Quiz, Response}

  @impl GenServer
  def init({quiz, email}) do
    {:ok, {quiz, email}}
  end

  @impl GenServer
  def handle_call(:select_question, _from, {quiz, email}) do
    quiz = Quiz.select_question(quiz)
    {:reply, quiz.current_question.asked, {quiz, email}}
  end

  @impl GenServer
  def handle_call({:answer_question, answer}, _from, {quiz, email}) do
    quiz
    |> Quiz.answer_question(Response.new(quiz, email, answer))
    |> Quiz.select_question()
    |> maybe_finish(email)
  end

  @impl GenServer
  def child_spec({quiz, email}) do
    %{
      id: {__MODULE__, {quiz.title, email}},
      start: {__MODULE__, :start_link, [{quiz, email}]},
      restart: :temporary
    }
  end

  def start_link({quiz, email}) do
    GenServer.start_link(__MODULE__, {quiz, email}, name: via({quiz.title, email}))
  end

  def take_quiz(quiz, email) do
    # This tells the top level Mastery.Supervisor.QuizSession to start a new quiz session process
    # See application.ex for more details. This will end up calling child_spec/1 with the passed {quiz, email} tuple
    DynamicSupervisor.start_child(Mastery.Supervisor.QuizSession, {__MODULE__, {quiz, email}})
  end

  def via({_title, _email} = name) do
    {:via, Registry, {Mastery.Registry.QuizSession, name}}
  end

  def select_question(name) do
    GenServer.call(via(name), :select_question)
  end

  def answer_question(name, answer) do
    GenServer.call(via(name), {:answer_question, answer})
  end

  def active_sessions_for(quiz_title) do
    Mastery.Supervisor.QuizSession
    |> DynamicSupervisor.which_children()
    |> Enum.filter(&child_pid?/1)
    |> Enum.flat_map(&active_sessions(&1, quiz_title))
  end

  def end_sessions(names) do
    Enum.each(names, fn name -> GenServer.stop(via(name)) end)
  end

  defp maybe_finish(nil, _email), do: {:stop, :normal, :finished, nil}

  defp maybe_finish(quiz, email) do
    {:reply, {quiz.current_question.asked, quiz.last_response.correct}, {quiz, email}}
  end

  defp child_pid?({:undefined, pid, :worker, [__MODULE__]}) when is_pid(pid), do: true
  defp child_pid?(_child), do: false

  def active_sessions({:undefined, pid, :worker, [__MODULE__]}, title) do
    Mastery.Registry.QuizSession
    |> Registry.keys(pid)
    |> Enum.filter(fn {quiz_title, _email} -> quiz_title == title end)
  end
end

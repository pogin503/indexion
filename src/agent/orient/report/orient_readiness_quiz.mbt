///|
/// Build readiness quiz questions from selected owners, knowledge sources,
/// consumer surfaces, forbidden paths, and required preflight evidence.
pub fn readiness_quiz(
  owners : Array[AgentOrientItem],
  knowledge_sources : Array[AgentOrientItem],
  consumers : Array[AgentOrientItem],
  forbidden : Array[AgentOrientItem],
  preflight : Array[AgentOrientItem],
) -> Array[AgentOrientQuizItem] {
  let quiz : Array[AgentOrientQuizItem] = []
  if owners.length() > 0 {
    quiz.push({
      question: "Which implementation area should own the first core change?",
      expected_answer: owners[0].path,
      evidence_path: owners[0].path,
    })
  }
  if knowledge_sources.length() > 0 {
    quiz.push({
      question: "Name one knowledge source that should inform the task.",
      expected_answer: knowledge_sources[0].path,
      evidence_path: knowledge_sources[0].path,
    })
  }
  if forbidden.length() > 0 {
    quiz.push({
      question: "Name one path where domain logic must not be added.",
      expected_answer: forbidden[0].path,
      evidence_path: forbidden[0].path,
    })
  } else if consumers.length() > 0 {
    quiz.push({
      question: "Name one consumer surface that should call core APIs instead of owning domain logic.",
      expected_answer: consumers[0].path,
      evidence_path: consumers[0].path,
    })
  }
  if preflight.length() > 0 {
    let evidence = first_owner_preflight(preflight)
    quiz.push({
      question: "Which evidence path should be read before editing?",
      expected_answer: evidence.path,
      evidence_path: evidence.path,
    })
  }
  quiz
}

///|
pub fn first_owner_preflight(
  preflight : Array[AgentOrientItem],
) -> AgentOrientItem {
  for item in preflight {
    if !item.reason.contains("consumer") && !item.reason.contains("CLI") {
      return item
    }
  }
  preflight[0]
}

Use this prompt with another AI model (or even here later) to generate concise slide content without overcrowding:

```text
You are helping prepare a 20-minute undergraduate technical presentation on a Functional ETL Framework implemented in OCaml.

I will provide:
1. A design document
2. API documentation
3. The slide structure

Your task:
- Generate ONLY the textual content for each slide.
- Do NOT generate full slides or presentation formatting.
- Keep content concise and presentation-friendly.
- Use short bullet points.
- Avoid paragraphs unless absolutely necessary.
- Avoid overcrowding slides.
- Prioritize clarity over completeness.
- Each slide should contain only the most important information needed to explain the idea verbally.
- Add small code snippets ONLY when they significantly improve understanding.
- Keep code snippets short (3–8 lines maximum).
- Avoid excessive theoretical explanations.
- Focus on practical interpretation of concepts.
- Use simple academic language suitable for an undergraduate project presentation.
- When explaining FP concepts (GADTs, monads, laziness), explain them in terms of practical ETL benefits rather than pure theory.
- Mention implementation details only if they support the main design idea.
- The audience is a professor familiar with programming languages and software engineering.

Presentation Goal:
Demonstrate:
- Why functional programming is suitable for ETL pipelines
- How the framework achieves composability, laziness, and type safety
- How GADTs improve schema/type correctness
- How the framework compares to imperative ETL approaches

For each slide output:
- Slide Title
- 3–6 concise bullet points
- Optional “Speaker Notes” section ONLY if the slide needs clarification during presentation
- Optional tiny code snippet if useful

Avoid:
- Long paragraphs
- Too many APIs on one slide
- Deep category theory
- Full implementation details
- Large code blocks
- Repeating information across slides

Slide Structure:

1. Motivation + What ETL Pipelines Are
   - Explain ETL briefly
   - Give one practical example
   - Introduce our functional ETL framework

2. Why Functional Programming for ETL
   - Immutability
   - Composability
   - Declarative pipelines
   - Lazy evaluation

3. Framework Architecture Overview
   - Extract → Transform → Load
   - Seq.t streaming
   - Separation of pure and impure components

4. Row + Column Representation
   - Row as immutable string map
   - Column as typed descriptor
   - Typed field access

5. GADT-Based Type Safety
   - Explain GADT column representation
   - Show how types are inferred
   - Explain compile-time safety benefits

6. Schema + Validation
   - Schema representation
   - Field/type validation
   - Schema-driven parsing

7. Transform APIs
   - map
   - filter
   - flat_map
   - group_by_aggregate
   - composable transformations

8. Pipeline Composition + Lazy Execution
   - Seq.t laziness
   - Pull-based execution
   - Result monad propagation
   - Execution triggered only at load stage

9. Error Handling + Bad Row Strategy
   - Error rows as values
   - filter_ok
   - strict vs tolerant pipelines
   - non-crashing ETL behavior

10. Example Declarative Pipeline
   - End-to-end example
   - Emphasize readability and composability
   - Show concise pipeline flow

11. Imperative Pandas Comparison
   - Mutable vs immutable
   - Eager vs lazy
   - Runtime vs compile-time safety
   - Declarative composition comparison

12. Conclusion + Learnings
   - Key achievements
   - FP concepts applied
   - Lessons learned
   - Possible future improvements

Important:
The slides should feel visually light.
Assume the presenter will verbally explain details.
The text should support speaking, not replace it.
```


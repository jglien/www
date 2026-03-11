import { describe, it, expect } from "vitest";
import { sortPostsByDate, type Post } from "./posts";

const makePost = (date: string): Post => ({
  frontmatter: { title: "T", description: "D", date },
  url: "/posts/t",
});

describe("sortPostsByDate", () => {
  it("sorts newest first", () => {
    const posts = [
      makePost("2022-01-01"),
      makePost("2024-06-15"),
      makePost("2023-03-10"),
    ];
    const sorted = sortPostsByDate(posts);
    expect(sorted.map((p) => p.frontmatter.date)).toEqual([
      "2024-06-15",
      "2023-03-10",
      "2022-01-01",
    ]);
  });

  it("handles a single post", () => {
    const posts = [makePost("2023-01-01")];
    expect(sortPostsByDate(posts)).toHaveLength(1);
  });

  it("handles an empty array", () => {
    expect(sortPostsByDate([])).toEqual([]);
  });

  it("does not mutate the original array", () => {
    const posts = [makePost("2022-01-01"), makePost("2024-01-01")];
    const original = [...posts];
    sortPostsByDate(posts);
    expect(posts).toEqual(original);
  });
});

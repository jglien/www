export interface PostFrontmatter {
  title: string;
  description: string;
  date: string;
}

export interface Post {
  frontmatter: PostFrontmatter;
  url?: string;
}

export function sortPostsByDate(posts: Post[]): Post[] {
  return [...posts].sort((a, b) =>
    b.frontmatter.date > a.frontmatter.date ? 1 : -1
  );
}

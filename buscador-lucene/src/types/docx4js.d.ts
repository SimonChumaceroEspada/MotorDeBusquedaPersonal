declare module "docx4js" {
  export function load(filePath: string): Promise<{ getFullText(): string }>;
}

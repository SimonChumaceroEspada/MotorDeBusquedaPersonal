declare module "pdf-parse" {
    function pdf(data: Buffer): Promise<{ text: string }>;
    export = pdf;
  }
  
  declare module "textract" {
    function fromFileWithPath(
      filePath: string,
      callback: (error: Error | null, text: string) => void
    ): void;
    export { fromFileWithPath };
  }

  declare module "docx4js" {
    export function load(filePath: string): Promise<{ getFullText(): string }>;
  }

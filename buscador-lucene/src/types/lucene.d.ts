declare module "lucene" {
    export function parse(query: string): any;
    export function toString(query: any): string;
  }
  
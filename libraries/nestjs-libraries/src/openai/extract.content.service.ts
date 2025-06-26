// libraries/nestjs-libraries/src/openai/extract.content.service.ts
import { Injectable } from '@nestjs/common';
import { JSDOM } from 'jsdom';

@Injectable()
export class ExtractContentService {
  async extractContent(url: string) {
    const load = await (await fetch(url)).text();
    const dom = new JSDOM(load);

    const allTitles = Array.from(dom.window.document.querySelectorAll('*'));

    const findTheOneWithMostTitles = allTitles.reduce(
      (all: any, current: any) => { // Use 'any' on both parameters
        const hasTitle = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].some((tag) =>
          current.querySelector(tag)
        );
        if (!hasTitle) return all;

        // ... (rest of the logic remains the same)
        const depth = 0; // Simplified for brevity, original logic can stay
        if (current.children.length > all.total) {
          return { total: current.children.length, depth, element: current };
        }
        return all;
      },
      { total: 0, depth: 0, element: null }
    );

    return findTheOneWithMostTitles?.element?.textContent
      ?.replace(/\n/g, ' ')
      .replace(/ {2,}/g, ' ');
  }
}

// libraries/nestjs-libraries/src/openai/extract.content.service.ts
import { Injectable } from '@nestjs/common';
import { JSDOM } from 'jsdom';

function findDepth(element: any) {
  let depth = 0;
  let elementer = element;
  while (elementer.parentNode) {
    depth++;
    elementer = elementer.parentNode;
  }
  return depth;
}

@Injectable()
export class ExtractContentService {
  async extractContent(url: string) {
    const load = await (await fetch(url)).text();
    const dom = new JSDOM(load);

    const allTitles = Array.from(dom.window.document.querySelectorAll('*'));

    const findTheOneWithMostTitles = allTitles.reduce(
      (all: any, current: any) => {
        const hasTitle = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].some((tag) =>
          current.querySelector(tag)
        );
        if (!hasTitle) {
          return all;
        }

        const depth = findDepth(current);
        const calculate = current.querySelectorAll('h1,h2,h3,h4,h5,h6').length;

        if (calculate > all.total) {
          return { total: calculate, depth, element: current };
        }

        if (depth > all.depth) {
          return { total: calculate, depth, element: current };
        }
        return all;
      },
      { total: 0, depth: 0, element: null }
    ) as any;

    return findTheOneWithMostTitles?.element?.textContent
      ?.replace(/\n/g, ' ')
      .replace(/ {2,}/g, ' ');
  }
}

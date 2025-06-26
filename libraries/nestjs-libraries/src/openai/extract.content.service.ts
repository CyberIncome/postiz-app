import { Injectable } from '@nestjs/common';
import { JSDOM } from 'jsdom';

// Define the shape of the object we are building in the reducer
type BestElementAccumulator = {
  total: number;
  depth: number;
  element: Element | null;
};

function findDepth(element: Element) {
  let depth = 0;
  let elementer = element;
  while (elementer.parentNode) {
    depth++;
    // @ts-ignore
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

    const findTheOneWithMostTitles = allTitles.reduce<BestElementAccumulator>(
      (all, current) => {
        const hasTitle = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].some((tag) =>
          current.querySelector(tag)
        );

        if (!hasTitle) {
          return all;
        }
        
        const depth = findDepth(current);
        const calculate = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].reduce(
          (total, tag) => {
            if (current.querySelector(tag)) {
              return total + 1;
            }
            return total;
          },
          0
        );

        if (calculate > all.total) {
          return { total: calculate, depth, element: current };
        }

        if (depth > all.depth) {
          return { total: calculate, depth, element: current };
        }

        return all;
      },
      { total: 0, depth: 0, element: null } // Initial Value
    );

    return findTheOneWithMostTitles?.element?.textContent
      ?.replace(/\n/g, ' ')
      .replace(/ {2,}/g, ' ');
  }
}

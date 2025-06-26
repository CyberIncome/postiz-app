import { Injectable } from '@nestjs/common';
import { JSDOM } from 'jsdom';

// ... (findDepth function remains the same)
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

    const allTitles = Array.from(dom.window.document.querySelectorAll('*'))
      .filter((f: any) => { // Use 'any' to fix filter error
        return (
          f.querySelector('h1') ||
          f.querySelector('h2') ||
          f.querySelector('h3') ||
          f.querySelector('h4') ||
          f.querySelector('h5') ||
          f.querySelector('h6')
        );
      })
      .reverse();

    const findTheOneWithMostTitles = allTitles.reduce((all, current: any) => { // Use 'any' for current
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
    }, { total: 0, depth: 0, element: null as Element | null }) as any; // Cast final result to 'any'

    return findTheOneWithMostTitles?.element?.textContent
      ?.replace(/\n/g, ' ')
      .replace(/ {2,}/g, ' ');
  }
}

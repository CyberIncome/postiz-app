// apps/backend/src/api/routes/copilot.controller.ts

import { Controller, Post, Req, Res } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '@gitroom/nestjs-libraries/services/auth/public.decorator';
import { CopilotKit } from '@copilotkit/runtime';
import { Request, Response } from 'express';

@ApiTags('Copilot')
@Controller('/copilot')
@Public()
export class CopilotController {
  @Post()
  chat(@Req() req: Request, @Res() res: Response): void { // Added ': void' return type
    const copilotKit = new CopilotKit({
      // langserve: [
      //   new LangserveAdapter({
      //     url: "http://localhost:8080/cities"
      //   }),
      // ],
    });

    copilotKit.stream(req.body, res);
  }
}

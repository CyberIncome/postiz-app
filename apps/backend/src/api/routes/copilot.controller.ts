// apps/backend/src/api/routes/copilot.controller.ts
import { Controller, Post, Req, Res } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '@gitroom/nestjs-libraries/services/auth/public.decorator';
import { CopilotRuntime } from '@copilotkit/runtime';
import { Request, Response } from 'express';

@ApiTags('Copilot')
@Controller('/copilot')
@Public()
export class CopilotController {
  @Post()
  chat(@Req() req: Request, @Res() res: Response): void {
    const copilotRuntime = new CopilotRuntime({}); // Corrected variable name
    copilotRuntime.stream(req.body, (chunk) => res.write(chunk));
  }
}

import readline from 'readline';
import * as Diff from 'diff';
import OpenAI from 'openai';

// TODO: Better markers for diff e.g. invisible unicode characters
const ADD_START='追追追';
const DEL_START='削削削';
const DIFF_END='終終終';

function question(query: string): Promise<string> {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
  
    return new Promise(resolve => rl.question(query, answer => {
      rl.close();
      resolve(answer);
    }));
}

function buildPrompt(partialCommand: string, requirement: string): string {
    const prompt = `
    Below is a partial command.

    ${partialCommand}

    Here are the requirements.

    「${requirement}」

    Infer the intent behind the requirements and suggest up to 5 modifications to the command line. Separate each suggestion with a new line and format each line as follows:
    
    command_part@@@description@@@full_command

    Where:

    - command_part: The part of the command line to add (if removing, use remove: followed by the part to be removed)
    - description: A description of the modification
    - full_command: The complete command line.

    First, you think the full_command to satisfy the requirements. Then you can think command_part where highlights the most important parts of your modification. Finally, you can write a description of the modification.
    Please output only command_part is relevant suggestion to the requirements.

    Strictly maintain the order of the columns. Only use this format for the output. Do not enclose the output in a Markdown code block.`;
    return prompt;
}

function processDiff(partialCommand: string, completeCommand: string): string {   
    const diffColoredStr = Diff.diffWordsWithSpace(partialCommand, completeCommand, {ignoreWhitespace: true}).map(part => {
        if (part.added) {
            return `${ADD_START}${part.value}${DIFF_END}`;
        }
        if (part.removed) {
            return `${DEL_START}${part.value}${DIFF_END}`;
        }
        return part.value;
    }).join('');

    return diffColoredStr;
}

function toTsv(partialCommand: string, aiLine: string): string {
    // just in case AI outputs more than four fields, we concats the rest as completeCommand
    const [commandPart, description, ...rest] = aiLine.split('@@@');
    const completeCommand = rest.join('');
    const diffColoredStr = processDiff(partialCommand, completeCommand);
    const tsv = [commandPart, description, completeCommand, diffColoredStr].join('\t');

    return tsv
}

async function main() {
    const partialCommand = process.argv[2];
    const requirement = process.argv[3];
    const ans = requirement ? requirement : await question('What do you want to do: ');

    const prompt = buildPrompt(partialCommand, ans);

    const openai = new OpenAI();
    const stream = openai.beta.chat.completions.stream({
        model: process.env.MANAI_MODEL ?? 'gpt-4o',
        messages: [
            { role: 'system', content: prompt },
        ],
        stream: true,
    });

    // const completion = await stream.finalContent();
    // const filteredLines = completion?.split('\n').map(e => e.replaceAll('@@@', '\t')).filter((line) => line.length > 0);
    // console.log(filteredLines?.join('\n'));

    let buffer: string = "";

    stream.on('content', (contentDelta) => {
        buffer += contentDelta;
        const lines = buffer.split('\n');
        const completeLines = lines.slice(0, -1);
        const incompleteLine = lines.slice(-1)[0];

        for (const line of completeLines) {
            if (line.length === 0) {
                continue;
            }

            console.log(toTsv(partialCommand, line));
        }

        buffer = incompleteLine;
    });

    await stream.finalContent();
    if (buffer.length > 0) {
        console.log(toTsv(partialCommand, buffer));
    }
}

main();

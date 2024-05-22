import readline from 'readline';
import OpenAI from 'openai';

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

    The command_part should align as closely as possible with the partial command line, reflecting the differences. For instance, if the partial command is empty, command_part would be the same as the full_command.

    Strictrly maintain the order of the columns. Only use this format for the output. Do not enclose the output in a Markdown code block.`;
    return prompt;
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
    stream.on('content', (contentDelta, contentSnapshot) => {
        buffer += contentDelta;
        const lines = buffer.split('\n');
        const completeLines = lines.slice(0, -1);
        const incompleteLine = lines.slice(-1)[0];

        for (const line of completeLines) {
            if (line.length === 0) {
                continue;
            }
            const tsv = line.replaceAll('@@@', '\t');
            console.log(tsv);
        }

        buffer = incompleteLine;
    });
    
    try {
        await stream.finalContent();
    } catch (e) {
        console.error(e);
        process.exit(1);
    }

    if (buffer.length > 0) {
        const tsv = buffer.replaceAll('@@@', '\t');
        console.log(tsv);
    }
}

main();

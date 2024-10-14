import fs from 'fs';

const inputFile = 'Hello.md'
const efsPath = '/mnt/efs'

export const handler = async () => {
  const hello: string = '👋 Lets get started!';
  console.log(hello);

  try {
    const filePath = `${efsPath}/${inputFile}`;
    const fileContent = fs.readFileSync(filePath, 'utf8');
    console.log('File content:', fileContent);
  } catch (error) {
    console.error('Error reading file:', error);
  }
};

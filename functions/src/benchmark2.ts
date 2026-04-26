const wait = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

async function sequential(items: number[]) {
  const start = Date.now();
  for (let i = 0; i < items.length; i++) {
    await wait(10);
  }
  return Date.now() - start;
}

async function concurrent(items: number[]) {
  const start = Date.now();
  await Promise.all(items.map(() => wait(10)));
  return Date.now() - start;
}

async function run() {
  const items = Array.from({length: 100}).map((_, i) => i);
  const seqTime = await sequential(items);
  const conTime = await concurrent(items);
  console.log(`Sequential: ${seqTime}ms`);
  console.log(`Concurrent: ${conTime}ms`);
}

run();

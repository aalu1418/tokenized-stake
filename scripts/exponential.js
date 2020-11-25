// proving efficiency of exponetiation function (returns number of loops)
const BN = require('bn.js');

const linear = (base, n) => {
  // let res = 1;
  // for (let i = 0; i < n; i++) {
  //   res *= base;
  // }
  return n;
};

const squaring = (base, n) => {
  const square = base * base;
  let res = 1;

  const loops = (n - (n % 2)) / 2;
  // for (let i = 0; i < loops; i++) {
  //   res *= square;
  // }
  //
  // if (n % 2 == 1) {
  //   res *= base;
  // }

  return loops;
};

const binary = (base, n) => {
  const bases = [];
  for (let i = 0; i < 26; i++) {
    bases.push(2 ** i);
  }

  let loops = 0;
  for (let i = 26; i > 0; i--) {
    let n_new = n;
    n_new = n % bases[i - 1];
    loops += (n - n_new) / bases[i - 1];
    if (n_new == 0) {
      break;
    } else {
      n = n_new;
    }
  }

  return loops;
};

const print = () => {
  let base = []
  for (let i = 0; i <= 28; i++){
    base.push(2**i);
  }
  console.log(String(base));
}

const main = () => {
  const base = 1;
  const n = 2*60*60*24*365*10;
  console.log("Years: "+String(n/(2*60*60*24*365)));

  console.log("Linear:", linear(base, n), "Squared:", squaring(base, n), "Binary:", binary(base, n));

  print();
};

main();

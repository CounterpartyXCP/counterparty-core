use std::{
    cmp::Reverse,
    collections::{BinaryHeap, HashMap},
};

use crossbeam_channel::{select, Receiver, Sender};

use crate::indexer::types::{
    error::Error,
    pipeline::{Done, HasHeight},
};

pub fn new<T: HasHeight>(
    start_height: u32,
) -> impl Fn(Receiver<Box<T>>, Sender<Box<T>>, Done) -> Result<(), Error> + Clone {
    move |rx, tx, done| {
        let mut heap = BinaryHeap::new();
        let mut next_index = start_height;
        let mut pending_blocks = HashMap::new();

        loop {
            select! {
                recv(done) -> _ => {
                  return Ok(())
                },
                recv(rx) -> result => {
                    let data = match result {
                        Ok(data) => data,
                        Err(_) => return Ok(()),
                    };
                    let data_height = data.get_height();
                    heap.push(Reverse(data_height));
                    pending_blocks.insert(data_height, data);
                    while let Some(&Reverse(maybe_next_index)) = heap.peek() {
                        if maybe_next_index == next_index {
                            heap.pop();
                            if let Some(data) = pending_blocks.remove(&next_index) {
                                if tx.send(data).is_err() {
                                    return Ok(());
                                }
                                next_index += 1;
                            }
                        } else {
                            break;
                        }
                    }
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::indexer::test_utils::test_worker;

    use super::*;
    use derive_more::{From, IntoIterator};
    use quickcheck::{Arbitrary, Gen, QuickCheck, TestResult};
    use rand::prelude::SliceRandom;

    #[derive(Debug, Clone, PartialEq)]
    struct MockData {
        height: u32,
    }

    impl HasHeight for MockData {
        fn get_height(&self) -> u32 {
            self.height
        }
    }

    #[derive(Debug, Clone, From, IntoIterator)]
    struct MockDataVec(Vec<MockData>);

    impl Arbitrary for MockDataVec {
        fn arbitrary(g: &mut Gen) -> Self {
            let len = usize::arbitrary(g) % 10 + 1;
            let mut vec: Vec<MockData> = (1..=len as u32).map(|i| MockData { height: i }).collect();

            let mut rng = rand::thread_rng();
            vec.shuffle(&mut rng);

            MockDataVec(vec)
        }
    }

    #[test]
    fn test_orderer_worker() {
        fn orderer_correctly_orders_heights(input_data: MockDataVec) -> TestResult {
            let mut expected = input_data.clone().into_iter().collect::<Vec<_>>();
            expected.sort_by_key(|d| d.height);
            let outputs = test_worker(new(1), input_data);
            if outputs == expected {
                TestResult::passed()
            } else {
                TestResult::failed()
            }
        }

        QuickCheck::new()
            .tests(100)
            .quickcheck(orderer_correctly_orders_heights as fn(MockDataVec) -> TestResult);
    }
}

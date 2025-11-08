/// identity hashed MRU table with 56-bit key and 8-bit value
pub(crate) struct TranspositionTable {
    records: Vec<u64>,
}
impl TranspositionTable {
    pub(crate) fn new(size: usize) -> Self {
        Self {
            records: vec![0; size],
        }
    }

    fn index(&self, key: u64) -> usize {
        (key % self.records.len() as u64) as usize
    }
    pub(crate) fn put(&mut self, key: u64, value: i8) {
        let idx = self.index(key);
        self.records[idx] = ((key as i64) << 8 | (value as i64)) as u64;
    }
    pub(crate) fn get(&self, key: u64) -> Option<i8> {
        let idx = self.index(key);
        let r = self.records[idx];
        if r >> 8 == key {
            Some((r & 0xff) as u8 as i8)
        } else {
            None
        }
    }
}

impl Default for TranspositionTable {
    fn default() -> Self {
        Self::new(8388593)
    }
}

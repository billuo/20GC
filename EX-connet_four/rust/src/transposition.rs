use crate::position::Position;
use num_traits::PrimInt;
use num_traits::sign::Unsigned;
use std::marker::PhantomData;
use std::mem::size_of;

/// identity hashed MRU table
pub(crate) struct MRUTable<K, PK, V> {
    keys: Vec<PK>,
    values: Vec<V>,
    _phantom: PhantomData<K>,
}

impl<K: PrimInt + Unsigned, PK: PrimInt + Unsigned, V: PrimInt + Unsigned> MRUTable<K, PK, V> {
    pub(crate) fn new(log_size: usize) -> Self {
        assert!(size_of::<K>() <= 8);
        assert!(size_of::<PK>() <= size_of::<K>());
        let size = next_prime(1 << log_size);
        Self {
            keys: vec![PK::zero(); size],
            values: vec![V::zero(); size],
            _phantom: Default::default(),
        }
    }

    fn k_to_pk(key: K) -> PK {
        // safety: new() asserted: size_of::<K>() <= 8
        let key = unsafe { key.to_u64().unwrap_unchecked() };
        match size_of::<PK>() {
            1 => unsafe { PK::from(key as u8).unwrap_unchecked() },
            2 => unsafe { PK::from(key as u16).unwrap_unchecked() },
            4 => unsafe { PK::from(key as u32).unwrap_unchecked() },
            _ => unimplemented!(),
        }
    }
    fn index(&self, key: K) -> usize {
        // safety: new() asserted: size_of::<K>() <= 8
        let key = unsafe { key.to_u64().unwrap_unchecked() };
        (key % self.keys.len() as u64) as usize
    }

    pub fn size(&self) -> usize {
        self.keys.len()
    }

    pub fn put(&mut self, key: K, value: V) {
        let idx = self.index(key);
        self.keys[idx] = Self::k_to_pk(key);
        self.values[idx] = value;
    }
    pub fn get(&self, key: K) -> Option<V> {
        let idx = self.index(key);
        if self.keys[idx] == Self::k_to_pk(key) {
            Some(self.values[idx])
        } else {
            None
        }
    }
}

impl<K: PrimInt + Unsigned, PK: PrimInt + Unsigned, V: PrimInt + Unsigned> Default
    for MRUTable<K, PK, V>
{
    fn default() -> Self {
        Self::new(23)
    }
}

const fn has_factor(n: usize, min: usize, max: usize) -> bool {
    if min * min > n {
        return false;
    }
    if min + 1 >= max {
        return n.is_multiple_of(min);
    }
    has_factor(n, min, (min + max) / 2) || has_factor(n, (min + max) / 2, max)
}

const fn next_prime(n: usize) -> usize {
    if has_factor(n, 2, n) {
        next_prime(n + 1)
    } else {
        n
    }
}

pub struct OpeningBook {
    table: MRUTable<u64, u16, u8>,
    depth: usize,
}
impl OpeningBook {
    pub fn get(&self, position: &Position) -> Option<i32> {
        if position.n_moves() > self.depth {
            None
        } else {
            self.table.get(position.key3()).map(|v| v as i8 as i32 - 19)
        }
    }
}

pub fn load_opening_book() -> OpeningBook {
    let (header, data) = include_bytes!("7x6_small.book").split_at(6);
    let w = header[0] as usize;
    let h = header[1] as usize;
    let depth = header[2] as usize;
    let pk_size = header[3] as usize;
    let v_size = header[4] as usize;
    let log_size = header[5] as usize;
    assert_eq!(w, 7);
    assert_eq!(h, 6);
    assert_eq!(pk_size, 2);
    assert_eq!(v_size, 1);
    eprintln!("{w}x{h} depth={depth} bytes={pk_size},{v_size} log_size={log_size}");
    eprintln!(
        "size=next_prime(1<<{log_size})={}",
        next_prime(1 << log_size)
    );
    let mut table = MRUTable::<u64, u16, u8>::new(log_size);
    let (keys_bytes, value_bytes) = data.split_at(pk_size * table.size());
    assert_eq!(value_bytes.len(), table.size());
    unsafe {
        table
            .keys
            .as_mut_ptr()
            .copy_from(keys_bytes.as_ptr() as *const u16, table.size());
        table
            .values
            .as_mut_ptr()
            .copy_from(value_bytes.as_ptr(), table.size());
    }
    OpeningBook { table, depth }
}

#[cfg(test)]
mod test {
    use super::*;
    #[test]
    fn load_opening_book() {
        let book = super::load_opening_book();
        let test_case = |code: &str| {
            let mut p = Position::default();
            p.apply_str(code);
            eprintln!("{code} {}", book.get(&p).unwrap());
        };
        test_case("352");
        test_case("32453");
        test_case("11122");
    }
}

fn main() -> u256 {
    add(8, 10)
}

pub fn add(left: u256, right: u256) -> u256 {
    left + right
}


#[cfg(test)]
mod tests {
    use super::add;

    #[test]
    fn test_addition() {
        let result = add(10, 11);

        assert(result == 20, 'addition failed');
    }
}

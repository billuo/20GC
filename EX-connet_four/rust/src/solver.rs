use crate::position::Position;

#[derive(Default)]
pub(crate) struct Solver {
    tt: crate::transposition::TranspositionTable,
}

impl Solver {
    fn negamax<T: Position + Copy>(position: &T) -> i32 {
        if position.n_moves() == T::WIDTH * T::HEIGHT {
            return 0;
        }
        for x in 0..T::WIDTH {
            if position.can_play(x) && position.is_winning_move(x) {
                return ((T::WIDTH * T::HEIGHT + 1 - position.n_moves()) / 2) as i32;
            }
        }
        let mut best_score = -((T::WIDTH * T::HEIGHT) as i32);
        for x in 0..T::WIDTH {
            if position.can_play(x) {
                let mut new_position = *position;
                new_position.play(x);
                let score = -Self::negamax(&new_position);
                if score > best_score {
                    best_score = score;
                }
            }
        }
        best_score
    }

    fn negamax_ab<T: Position + Copy>(position: &T, mut alpha: i32, mut beta: i32) -> i32 {
        if position.n_moves() == T::WIDTH * T::HEIGHT {
            return 0;
        }
        for x in 0..T::WIDTH {
            if position.can_play(x) && position.is_winning_move(x) {
                return ((T::WIDTH * T::HEIGHT + 1 - position.n_moves()) / 2) as i32;
            }
        }
        let max = ((T::WIDTH * T::HEIGHT - 1 - position.n_moves()) / 2) as i32;
        if beta > max {
            beta = max;
            if alpha >= beta {
                return beta;
            }
        }
        for x in 0..T::WIDTH {
            if position.can_play(x) {
                let mut new_position = *position;
                new_position.play(x);
                let score = -Self::negamax_ab(&new_position, -beta, -alpha);
                if score >= beta {
                    return score;
                }
                if score > alpha {
                    alpha = score;
                }
            }
        }
        alpha
    }

    fn negamax_ab_order<T: Position + Copy>(position: &T, mut alpha: i32, mut beta: i32) -> i32 {
        if position.n_moves() == T::WIDTH * T::HEIGHT {
            return 0;
        }
        for x in 0..T::WIDTH {
            if position.can_play(x) && position.is_winning_move(x) {
                return ((T::WIDTH * T::HEIGHT + 1 - position.n_moves()) / 2) as i32;
            }
        }
        let max = ((T::WIDTH * T::HEIGHT - 1 - position.n_moves()) / 2) as i32;
        if beta > max {
            beta = max;
            if alpha >= beta {
                return beta;
            }
        }
        for x in [3, 2, 4, 1, 5, 0, 6] {
            if position.can_play(x) {
                let mut new_position = *position;
                new_position.play(x);
                let score = -Self::negamax_ab_order(&new_position, -beta, -alpha);
                if score >= beta {
                    return score;
                }
                if score > alpha {
                    alpha = score;
                }
            }
        }
        alpha
    }

    fn negamax_ab_order_trans<T: Position + Copy>(
        &mut self,
        position: &T,
        mut alpha: i32,
        mut beta: i32,
    ) -> i32 {
        if position.n_moves() == T::WIDTH * T::HEIGHT {
            return 0;
        }
        for x in 0..T::WIDTH {
            if position.can_play(x) && position.is_winning_move(x) {
                return ((T::WIDTH * T::HEIGHT + 1 - position.n_moves()) / 2) as i32;
            }
        }
        let mut max = ((T::WIDTH * T::HEIGHT - 1 - position.n_moves()) / 2) as i32;
        if let Some(v) = self.tt.get(position.key()) {
            max = v as i32
        }
        if beta > max {
            beta = max;
            if alpha >= beta {
                return beta;
            }
        }
        for x in [3, 2, 4, 1, 5, 0, 6] {
            if position.can_play(x) {
                let mut new_position = *position;
                new_position.play(x);
                let score = -self.negamax_ab_order_trans(&new_position, -beta, -alpha);
                if score >= beta {
                    return score;
                }
                if score > alpha {
                    alpha = score;
                }
            }
        }
        self.tt.put(position.key(), alpha as i8);
        alpha
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use crate::position::ArrayPosition;
    use std::str::FromStr;
    #[test]
    fn negamax_with_negamax_ab_endgame() {
        let test_case = |code: &str| {
            let p = ArrayPosition::from_str(code).unwrap();
            let score1 = Solver::negamax(&p);
            let score2 = Solver::negamax_ab(&p, -100, 100);
            eprintln!("{code} negamax={score1} negamax_ab={score2}",);
            assert_eq!(score1, score2);
        };
        for i in 0..19 {
            test_case(&"01234560123456012345610325406214365"[0..35 - i]);
        }
    }
    #[test]
    fn negamax_ab_with_negamax_ab_order_endgame() {
        let test_case = |code: &str| {
            let p = ArrayPosition::from_str(code).unwrap();
            let score1 = Solver::negamax_ab(&p, -100, 100);
            let score2 = Solver::negamax_ab_order(&p, -100, 100);
            eprintln!("{code} negamax_ab={score1} negamax_ab_order={score2}",);
            assert_eq!(score1, score2);
        };
        for i in 0..19 {
            test_case(&"01234560123456012345610325406214365"[0..35 - i]);
        }
    }
    #[test]
    fn array_position_vs_bit_position() {
        let test_case = |code: &str| {
            let ap = ArrayPosition::from_str(code).unwrap();
            let bp = ap.to_bit_position();
            let score1 = Solver::negamax_ab_order(&ap, -100, 100);
            let score2 = Solver::negamax_ab_order(&bp, -100, 100);
            eprintln!("{code} <AP>negamax_ab_order={score1} <BP>negamax_ab_order={score2}",);
            assert_eq!(score1, score2);
        };
        for i in 0..19 {
            test_case(&"01234560123456012345610325406214365"[0..35 - i]);
        }
    }
    #[test]
    fn transposition_table() {
        let mut solver = Solver::default();
        let mut test_case = |code: &str| {
            let p = ArrayPosition::from_str(code).unwrap().to_bit_position();
            let score1 = Solver::negamax_ab_order(&p, -100, 100);
            let score2 = solver.negamax_ab_order_trans(&p, -100, 100);
            eprintln!("{code} negamax_ab_order={score1} negamax_ab_order_trans={score2}",);
            assert_eq!(score1, score2);
        };
        for i in 0..20 {
            test_case(&"01234560123456012345610325406214365"[0..35 - i]);
        }
    }
    #[test]
    fn transposition_table_2() {
        let mut solver = Solver::default();
        let mut test_case = |code: &str| {
            let p = ArrayPosition::from_str(code).unwrap().to_bit_position();
            let score = solver.negamax_ab_order_trans(&p, -100, 100);
            eprintln!("{code} negamax_ab_order_trans={score}",);
        };
        for i in 0..24 {
            test_case(&"01234560123456012345610325406214365"[0..35 - i]);
        }
    }
}

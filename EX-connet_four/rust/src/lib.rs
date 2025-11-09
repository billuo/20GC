use godot::prelude::*;

pub mod lookup;
pub mod position;
pub mod solver;

use position::Position;

#[derive(GodotClass)]
#[class(init)]
struct AnalyzedMove {
    /// column to play
    #[var]
    col: u32,
    /// score of the move, the more positive the better (more likely to win)
    #[var]
    score: i32,
    /// true if playing this move wins immediately
    #[var]
    winning: bool,
    /// true if playing this move loses immediately
    #[var]
    losing: bool,
    /// true if NOT playing this move loses immediately
    #[var]
    forced: bool,
}

impl AnalyzedMove {
    fn new(position: &Position, col: usize, score: i32) -> Self {
        let winning = position.is_winning_move(col);
        let losing = position.played(col).can_win_next();
        let forced = position.is_forced_move(col);
        Self {
            col: col as u32,
            score,
            winning,
            losing,
            forced,
        }
    }
}

#[derive(GodotClass)]
#[class(init)]
struct C4Solver {
    solver: solver::Solver,
}

#[godot_api]
impl C4Solver {
    #[func]
    fn solve(&mut self, moves: PackedByteArray, #[opt(default = true)] weak: bool) -> i32 {
        let mut position = Position::default();
        position.apply_moves(moves.as_slice().iter().map(|b| *b as usize));
        self.solver.solve(&position, weak)
    }

    #[func]
    fn analyze(
        &mut self,
        moves: PackedByteArray,
        #[opt(default = true)] weak: bool,
    ) -> Array<Option<Gd<AnalyzedMove>>> {
        let mut p = Position::default();
        p.apply_moves(moves.as_slice().iter().map(|b| *b as usize));
        self.solver
            .analyze(&p, weak)
            .into_iter()
            .enumerate()
            .map(|(i, s)| s.map(|s| Gd::from_object(AnalyzedMove::new(&p, i, -s))))
            .collect()
    }
}

struct MyExtension;
#[gdextension]
unsafe impl ExtensionLibrary for MyExtension {}

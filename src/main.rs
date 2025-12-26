use nannou::prelude::*;

fn grow_dragon(curve_spec: &mut Vec<bool>) {
    let tmp = curve_spec.to_owned();
    let back_half = tmp.iter().rev().map(|x| !x);
    curve_spec.push(true);
    curve_spec.extend(back_half);
}

fn main() {
    nannou::app(model).update(update).simple_window(view).run();
}

struct Model {
    depth: u8,
    edge: f32,
    points: Vec<Vec2>,
}

fn curve_len(i: usize) -> usize {
    pow(2, i) + (0..i).map(|x| pow(2, x)).sum::<usize>()
}

fn model(_app: &App) -> Model {
    let depth = 9;
    let edge = 300.;

    let mut curve: Vec<bool> = vec![true];
    for _ in 0..depth {
        grow_dragon(&mut curve);
    }

    let mut points: Vec<Vec2> = vec![pt2(0., -edge), pt2(0., 0.)];
    let mut rotation = Mat2::IDENTITY;
    let left: Mat2 = Mat2::from_cols_array(&[0., 1., -1., 0.]);
    let right: Mat2 = Mat2::from_cols_array(&[0., -1., 1., 0.]);

    for i in &curve {
        rotation = rotation * (if *i { right } else { left });
        points.push(*points.last().unwrap() + rotation * pt2(0., edge));
    }
    Model {
        points,
        depth,
        edge,
    }
}

fn update(_app: &App, _model: &mut Model, _update: Update) {}

fn view(app: &App, model: &Model, frame: Frame) {
    let draw = app.draw();
    draw.background().color(PLUM);
    // let step = 9;
    let step = app.duration.since_start.as_secs() as usize % model.depth as usize;
    let points = &model.points[0..curve_len(step)];
    let scale = 1. / step as f32;
    let mut i = 0;
    while i + 1 < curve_len(step) {
        println!("{} {} {}", points[i], points[i + 1], points[i + 2]);
        draw.tri()
            .points(
                scale * points[i],
                scale * points[i + 1],
                scale * points[i + 2],
            )
            .stroke(SALMON)
            .color(DARKSALMON);
        i += 2;
    }
    draw.to_frame(app, &frame).unwrap();
}

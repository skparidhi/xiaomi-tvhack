package com.gathin.tvhome;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.Shader;
import android.util.AttributeSet;
import android.view.View;

/**
 * Frosted glass tile background. Android 9 has no backdrop blur, so the wallpaper is blurred once
 * ({@link #prepare}) and each tile draws the patch of that blurred copy that sits behind it, then a
 * frost tint, a top-lit sheen, a bright outer rim and a faint inner rim.
 */
public class GlassTileView extends View {

    /** Blurred, downscaled wallpaper shared by every tile; same aspect as the screen. */
    private static Bitmap blurred;

    private final Paint bmp = new Paint(Paint.FILTER_BITMAP_FLAG | Paint.ANTI_ALIAS_FLAG);
    private final Paint frost = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint sheen = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint rim = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint innerRim = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final RectF rect = new RectF();
    private final Rect src = new Rect();
    private final Path clip = new Path();
    private final int[] loc = new int[2];
    private final float density;
    private final float radius;

    public GlassTileView(Context context, AttributeSet attrs) {
        super(context, attrs);
        density = getResources().getDisplayMetrics().density;
        radius = AppAdapter.TILE_RADIUS_DP * density;
        rim.setStyle(Paint.Style.STROKE);
        rim.setStrokeWidth(1.5f * density);
        innerRim.setStyle(Paint.Style.STROKE);
        innerRim.setStrokeWidth(density);
        innerRim.setColor(0x24FFFFFF);
    }

    /** Blurs the wallpaper by repeated down/up scaling: cheap, and fine for frosted glass. */
    static void prepare(Resources res, int wallpaperRes) {
        if (blurred != null) return;
        BitmapFactory.Options o = new BitmapFactory.Options();
        o.inSampleSize = 4;   // 1280x720 → 320x180 straight from the decoder
        Bitmap src = BitmapFactory.decodeResource(res, wallpaperRes, o);
        if (src == null) return;
        Bitmap b = src;
        for (int i = 0; i < 2; i++) {
            Bitmap down = Bitmap.createScaledBitmap(b, 64, 36, true);
            if (b != src) b.recycle();
            b = Bitmap.createScaledBitmap(down, 320, 180, true);
            down.recycle();
        }
        src.recycle();
        blurred = b;
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        frost.setShader(new LinearGradient(0, 0, 0, h, 0x1FFFFFFF, 0x05FFFFFF, Shader.TileMode.CLAMP));
        sheen.setShader(new LinearGradient(0, 0, 0, h * 0.45f, 0x2EFFFFFF, 0x00FFFFFF, Shader.TileMode.CLAMP));
        rim.setShader(new LinearGradient(0, 0, 0, h, 0xD9FFFFFF, 0x4DFFFFFF, Shader.TileMode.CLAMP));
    }

    @Override
    protected void onDraw(Canvas canvas) {
        float half = rim.getStrokeWidth() / 2f;
        rect.set(half, half, getWidth() - half, getHeight() - half);
        clip.reset();
        clip.addRoundRect(rect, radius, radius, Path.Direction.CW);

        canvas.save();
        canvas.clipPath(clip);
        if (blurred != null) {
            // The patch of the blurred wallpaper behind this tile (wallpaper is full screen, centre-cropped).
            getLocationOnScreen(loc);
            View screen = getRootView();
            float sx = blurred.getWidth() / (float) Math.max(1, screen.getWidth());
            float sy = blurred.getHeight() / (float) Math.max(1, screen.getHeight());
            float scale = ((View) getParent()).getScaleX();
            src.set((int) (loc[0] * sx), (int) (loc[1] * sy),
                    (int) ((loc[0] + getWidth() * scale) * sx), (int) ((loc[1] + getHeight() * scale) * sy));
            canvas.drawBitmap(blurred, src, rect, bmp);
            canvas.drawColor(0x14000000);   // a touch darker than the scene, so the white wordmarks hold
        }
        canvas.drawRect(rect, frost);
        canvas.drawRect(rect.left, rect.top, rect.right, rect.top + rect.height() * 0.45f, sheen);
        canvas.restore();

        canvas.drawRoundRect(rect, radius, radius, rim);
        float in = 3f * density;
        canvas.drawRoundRect(rect.left + in, rect.top + in, rect.right - in, rect.bottom - in,
                radius - in, radius - in, innerRim);
    }
}

import 'package:flutter/material.dart';

class HomeSlideshow extends StatefulWidget {
  final List<Map<String, String>> slides;
  final bool isMobile;

  const HomeSlideshow({super.key, required this.slides, this.isMobile = false});

  @override
  State<HomeSlideshow> createState() => _HomeSlideshowState();
}

class _HomeSlideshowState extends State<HomeSlideshow> {
  int _currentSlide = 0;
  final PageController _pageController = PageController();

   @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slideHeight = widget.isMobile ? 220.0 : 340.0;
    return Column(
      children: [
        SizedBox(
          height: slideHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _currentSlide = i),
            itemBuilder: (context, i) {
              final slide = widget.slides[i];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, slide['route']!),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Consider adding errorBuilder for network images if used later
                      Image.asset(
                        slide['image']!,
                        fit: BoxFit.cover,
                        color: Colors.black.withOpacity(0.25),
                        colorBlendMode: BlendMode.darken,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(slide['title']!, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(slide['desc']!, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
                            const SizedBox(height: 18),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, slide['route']!),
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                              child: const Text('Explore'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.slides.length, (i) => GestureDetector(
            onTap: () {
              _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 48,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: i == _currentSlide ? Theme.of(context).colorScheme.primary : Colors.grey.shade400, width: 2),
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(widget.slides[i]['image']!),
                  fit: BoxFit.cover,
                  colorFilter: i == _currentSlide ? null : ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                ),
              ),
            ),
          )),
        ),
      ],
    );
  }
} 


WORKING_BRANCH="jb-release"
NDK="~/arsiv/android/android-ndk-r11c/ndk-build"
PROJECT_DIR="Project"
ANDROID_REPLACEMENT_DIRECTORY="yapikredi"
ANDROID_REPLACEMENT_DIRECTORY_UPPERCASE="YAPIKREDI"
PACKAGE_NAME="com.$ANDROID_REPLACEMENT_DIRECTORY.inputmethod"
LC_CTYPE=C
LC_ALL=C


# get the template project
git clone https://github.com/korayucar/LatinIME-Android-Studio $PROJECT_DIR

#get LatinIme repository go to the chosen branch
git clone https://android.googlesource.com/platform/packages/inputmethods/LatinIME $PROJECT_DIR/LatinIME
cd $PROJECT_DIR/LatinIME
git checkout $WORKING_BRANCH
cd ../..


#get the inputcommon library and go to corresponding branch
git clone https://github.com/CyanogenMod/android_frameworks_opt_inputmethodcommon.git $PROJECT_DIR/inputmethodcommon
cd $PROJECT_DIR/inputmethodcommon
git checkout $WORKING_BRANCH

#ignore warnings during NDK compilation. !!!!!!! Red Flag !!!!!!
cd ..
sed -i.bak "s/-Werror//g" LatinIME/native/jni/Android.mk
rm LatinIME/native/jni/Android.mk.bak

#enable compilation of all architectures
echo "APP_ABI := all" >> LatinIME/native/jni/Application.mk
cd LatinIME/native

mv jni/com_android_inputmethod_keyboard_ProximityInfo.cpp jni/com_"$ANDROID_REPLACEMENT_DIRECTORY"_inputmethod_keyboard_ProximityInfo.cpp
mv jni/com_android_inputmethod_keyboard_ProximityInfo.h jni/com_"$ANDROID_REPLACEMENT_DIRECTORY"_inputmethod_keyboard_ProximityInfo.h
mv jni/com_android_inputmethod_latin_BinaryDictionary.cpp jni/com_"$ANDROID_REPLACEMENT_DIRECTORY"_inputmethod_latin_BinaryDictionary.cpp
mv jni/com_android_inputmethod_latin_BinaryDictionary.h jni/com_"$ANDROID_REPLACEMENT_DIRECTORY"_inputmethod_latin_BinaryDictionary.h
find jni -type f | xargs sed -i.bak "s/com_android_inputmethod/com_"$ANDROID_REPLACEMENT_DIRECTORY"_inputmethod/g"
find jni -type f | xargs sed -i.bak "s/com\/android\/inputmethod/com\/$ANDROID_REPLACEMENT_DIRECTORY\/inputmethod/g"
find jni -type f | xargs sed -i.bak "s/COM_ANDROID_INPUTMETHOD/COM_"$ANDROID_REPLACEMENT_DIRECTORY_UPPERCASE"_INPUTMETHOD/g"
#compile native code
eval $NDK
cd ../../..
# correct resource references in xml files necessary for newer android build systems
find . -type f | xargs sed -i.bak "s/http:\/\/schemas.android.com\/apk\/res\/com.android.inputmethod.latin/http:\/\/schemas.android.com\/apk\/res-auto/g"
find . -type f -name '*.bak' | xargs rm

#Correct deprecated class usage in specific file
sed -i.bak "s/FloatMath.sqrt/\(float\)Math.sqrt/g"  $PROJECT_DIR/LatinIME/java/src/com/android/inputmethod/keyboard/ProximityInfo.java
rm $PROJECT_DIR/LatinIME/java/src/com/android/inputmethod/keyboard/ProximityInfo.java.bak

# copy compiled native library to necessary location
mkdir -p Project/app/src/main/jniLibs/armeabi
mkdir -p Project/app/src/main/jniLibs/x86
cp Project/LatinIME/native/obj/local/armeabi/libjni_latinime.so Project/app/src/main/jniLibs/armeabi
cp Project/LatinIME/native/obj/local/x86/libjni_latinime.so Project/app/src/main/jniLibs/x86

# change package signature except native directory
find $PROJECT_DIR -type f | grep -v native | xargs  sed -i.bak "s/com\.android\.inputmethod/$PACKAGE_NAME/g"
find $PROJECT_DIR -type f -name '*.bak' | xargs rm
mv $PROJECT_DIR/LatinIME/java/src/com/android Project/LatinIME/java/src/com/$ANDROID_REPLACEMENT_DIRECTORY
mv $PROJECT_DIR/inputmethodcommon/java/com/android Project/inputmethodcommon/java/com/$ANDROID_REPLACEMENT_DIRECTORY




#settings activity must contain isValidActivity
if ! grep isValidFragment Project/LatinIME/java/src/com/$ANDROID_REPLACEMENT_DIRECTORY/inputmethod/latin/SettingsActivity.java; then
  cat > $PROJECT_DIR/LatinIME/java/src/com/$ANDROID_REPLACEMENT_DIRECTORY/inputmethod/latin/SettingsActivity.java << EOF
  package $PACKAGE_NAME.latin;

  import android.content.Intent;
  import android.preference.PreferenceActivity;

  public class SettingsActivity extends PreferenceActivity {
      private static final String DEFAULT_FRAGMENT = Settings.class.getName();

      @Override
      protected boolean isValidFragment(String fragmentName) {
          return true;
      }

      @Override
      public Intent getIntent() {
          final Intent intent = super.getIntent();
          if (!intent.hasExtra(EXTRA_SHOW_FRAGMENT)) {
              intent.putExtra(EXTRA_SHOW_FRAGMENT, DEFAULT_FRAGMENT);
          }
          intent.putExtra(EXTRA_NO_HEADERS, true);
          return intent;
      }
  }
EOF
cat $PROJECT_DIR/LatinIME/java/src/com/$ANDROID_REPLACEMENT_DIRECTORY/inputmethod/latin/SettingsActivity.java
fi
